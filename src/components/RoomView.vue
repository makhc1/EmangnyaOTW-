<script setup>
import { ref, onMounted, onUnmounted, nextTick } from 'vue'
import L from 'leaflet'
import 'leaflet/dist/leaflet.css'
import { Bike, Crosshair, ArrowUpRight, Share2, LogOut } from 'lucide-vue-next'
import { supabase } from '../supabase'
import { showToast } from '../toast'

const props = defineProps({
  roomId: String,
  user: Object
})
const emit = defineEmits(['leave'])

const statusMessage = ref('')
const mapContainer = ref(null)
const map = ref(null)
const memberMarkers = ref({})
const feed = ref([])
const members = ref([])
let geoWatchId = null
let channel = null

// Mobile Bottom Sheet State
const isChatExpanded = ref(false)
let touchStartY = 0

const copyShareLink = () => {
  const link = `${window.location.origin}${window.location.pathname}?room=${props.roomId}`
  navigator.clipboard.writeText(link)
  showToast('Link udah di-copy! Kasih ke temen lu cepet.', 'success')
}

const leaveRoom = () => {
  if (geoWatchId) navigator.geolocation.clearWatch(geoWatchId)
  if (channel) supabase.removeChannel(channel)
  emit('leave')
}

// -----------------------
// SUPABASE LOGIC
// -----------------------
const initRoom = async () => {
  const { data: room, error: roomErr } = await supabase
    .from('rooms')
    .select('id')
    .eq('id', props.roomId)
    .maybeSingle()
    
  if (!room) {
    await supabase.from('rooms').insert([{ id: props.roomId }])
  }

  // 1. Cek apakah user udah ada di tabel members
  const { data: existingUser } = await supabase
    .from('members')
    .select('id, lat, lng')
    .eq('id', props.user.id)
    .maybeSingle()

  if (existingUser) {
    // Kalau udah ada, update data doang (JANGAN TIMPA LAT & LNG)
    await supabase.from('members').update({ 
      room_id: props.roomId, 
      nickname: props.user.name, 
      avatar_url: props.user.avatar,
      last_updated: new Date().toISOString()
    }).eq('id', props.user.id)
  } else {
    // Kalau belum ada, insert baru
    await supabase.from('members').insert([{ 
      id: props.user.id, 
      room_id: props.roomId, 
      nickname: props.user.name, 
      avatar_url: props.user.avatar,
      last_updated: new Date().toISOString()
    }])
  }

  const { data: initialMembers } = await supabase
    .from('members')
    .select('*')
    .eq('room_id', props.roomId)
  if (initialMembers) members.value = initialMembers

  const { data: initialMessages } = await supabase
    .from('messages')
    .select('*, member:member_id(nickname, avatar_url)')
    .eq('room_id', props.roomId)
    .order('created_at', { ascending: false })
    .limit(50)
  
  if (initialMessages) {
    feed.value = initialMessages.map(m => ({
      id: m.id,
      name: m.member?.nickname || 'Unknown',
      avatar: m.member?.avatar_url || '',
      message: m.content,
      time: new Date(m.created_at).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
    }))
  }

  updateMapMarkers()
  setupRealtime()
  startTracking()
}

const setupRealtime = () => {
  channel = supabase.channel(`room:${props.roomId}`)
    .on('postgres_changes', { event: '*', schema: 'public', table: 'members', filter: `room_id=eq.${props.roomId}` }, payload => {
      const updatedMember = payload.new
      const index = members.value.findIndex(m => m.id === updatedMember.id)
      if (index !== -1) {
        members.value[index] = updatedMember
      } else {
        members.value.push(updatedMember)
      }
      updateMapMarkers()
    })
    .on('postgres_changes', { event: 'INSERT', schema: 'public', table: 'messages', filter: `room_id=eq.${props.roomId}` }, async payload => {
      const msg = payload.new
      let sender = members.value.find(m => m.id === msg.member_id)
      if (!sender) {
        const { data } = await supabase.from('members').select('*').eq('id', msg.member_id).maybeSingle()
        if (data) sender = data
      }
      feed.value.unshift({
        id: msg.id,
        name: sender?.nickname || 'Unknown',
        avatar: sender?.avatar_url || '',
        message: msg.content,
        time: new Date(msg.created_at).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
      })
    })
    .subscribe()
}

// -----------------------
// MAP & GEOLOCATION
// -----------------------
const escapeHtml = (unsafe) => {
  if (!unsafe) return ''
  return unsafe
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#039;")
}

const updateMapMarkers = () => {
  if (!map.value) return

  members.value.forEach(m => {
    if (!m.lat || !m.lng) return

    const safeAvatar = escapeHtml(m.avatar_url)
    const isMe = m.id === props.user.id
    const avatarHtml = isMe 
      ? `
      <div class="relative group z-50">
        <div class="absolute -bottom-2 -right-2 w-12 h-12 bg-black rounded-xl"></div>
        <div class="relative w-12 h-12 rounded-xl border-4 border-black bg-[#FFB800] overflow-hidden flex items-center justify-center p-0.5 animate-bounce">
           <img src="${safeAvatar}" class="w-full h-full object-cover bg-white" />
        </div>
        <div class="absolute -top-3 -right-3 bg-[#FF458A] text-white text-[9px] font-black uppercase px-2 py-0.5 rounded-full border-2 border-black rotate-12">YOU</div>
      </div>
      `
      : `
      <div class="relative group z-40 transition-transform hover:scale-110 hover:z-50">
        <div class="absolute -bottom-1 -right-1 w-10 h-10 bg-black rounded-xl"></div>
        <div class="relative w-10 h-10 rounded-xl border-4 border-black bg-[#00E5FF] overflow-hidden flex items-center justify-center p-0.5">
           <img src="${safeAvatar}" class="w-full h-full object-cover bg-white" />
        </div>
      </div>
      `

    if (memberMarkers.value[m.id]) {
      memberMarkers.value[m.id].setLatLng([m.lat, m.lng])
    } else {
      const icon = L.divIcon({
        html: avatarHtml,
        className: 'bg-transparent border-none',
        iconSize: isMe ? [48, 48] : [40, 40],
        iconAnchor: isMe ? [24, 24] : [20, 20]
      })
      const marker = L.marker([m.lat, m.lng], { icon }).addTo(map.value)
        .bindPopup(`<b>${m.nickname}</b>${isMe ? '<br>Current Location' : ''}`)
      
      memberMarkers.value[m.id] = marker
    }
  })
}

const startTracking = () => {
  if (navigator.geolocation) {
    geoWatchId = navigator.geolocation.watchPosition(
      async (position) => {
        const { latitude, longitude } = position.coords
        await supabase
          .from('members')
          .update({ lat: latitude, lng: longitude, last_updated: new Date().toISOString() })
          .eq('id', props.user.id)
          
        if (map.value && !memberMarkers.value[props.user.id]) {
           map.value.setView([latitude, longitude], 14)
        }
      },
      (error) => {
        console.warn("Geolocation error:", error)
        showToast("GPS lu mati bos, atau browser nggak dikasih izin akses lokasi!", "error")
      },
      { enableHighAccuracy: true, maximumAge: 10000, timeout: 5000 }
    )
  } else {
    showToast("Browser lu nggak support GPS bos!", "error")
  }
}

const findMe = () => {
  const me = members.value.find(m => m.id === props.user.id)
  if (me && me.lat && me.lng && map.value) {
    map.value.flyTo([me.lat, me.lng], 16, { duration: 1.5, easeLinearity: 0.25 })
  }
}

const updateStatus = async () => {
  if (!statusMessage.value.trim()) return
  
  const msg = statusMessage.value
  statusMessage.value = '' 
  
  await supabase.from('messages').insert([{
    room_id: props.roomId,
    member_id: props.user.id,
    content: msg
  }])
  
  findMe()
}

// -----------------------
// TOUCH GESTURES (BOTTOM SHEET)
// -----------------------
const handleTouchStart = (e) => {
  touchStartY = e.touches[0].clientY
}
const handleTouchEnd = (e) => {
  const touchEndY = e.changedTouches[0].clientY
  const deltaY = touchEndY - touchStartY
  
  if (deltaY < -40) {
    // Swipe Up -> Expand
    isChatExpanded.value = true
  } else if (deltaY > 40) {
    // Swipe Down -> Collapse
    isChatExpanded.value = false
  }
}

onMounted(() => {
  map.value = L.map(mapContainer.value, {
    zoomControl: false,
    attributionControl: false
  }).setView([-6.200000, 106.816666], 14)

  // Pakai CartoDB Positron (Terang / Light) biar UI Brutalism nya Pop-out
  L.tileLayer('https://basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png?key=cb1_3oje_1_8d4d89d96dd10e8be5a47ff7', {
    maxZoom: 20
  }).addTo(map.value)

  initRoom()
})

onUnmounted(() => {
  if (geoWatchId) navigator.geolocation.clearWatch(geoWatchId)
  if (channel) supabase.removeChannel(channel)
})
</script>

<template>
  <div class="absolute inset-0 z-0 bg-[#f4f4f0]">
    <!-- Map Canvas -->
    <div ref="mapContainer" class="absolute inset-0 z-0"></div>

    <!-- Main Content Wrapper -->
    <div class="relative z-10 w-full h-full pointer-events-none flex flex-col justify-between p-4 md:p-8">
      
      <!-- Top Nav Island (Brutalist) -->
      <header class="w-full max-w-sm mx-auto md:mx-0 md:max-w-md pointer-events-auto transform transition-all duration-300">
        <div class="bg-white border-4 border-black p-2 rounded-2xl shadow-[6px_6px_0px_0px_rgba(0,0,0,1)] flex items-center justify-between">
          <div class="flex items-center gap-3 pl-2">
            <div class="w-8 h-8 bg-[#FFB800] border-2 border-black rounded-lg flex items-center justify-center -rotate-6">
               <Bike class="w-5 h-5 text-black" stroke-width="2.5" />
            </div>
            <div class="flex flex-col">
               <h1 class="text-[11px] font-black tracking-widest text-black uppercase">PIN Room</h1>
               <span class="text-xs font-bold text-black/60 font-mono">{{ roomId.substring(0,8) }}...</span>
            </div>
          </div>
          <div class="flex items-center gap-2">
            <button @click="copyShareLink" class="w-10 h-10 rounded-xl bg-[#00E5FF] border-2 border-black flex items-center justify-center hover:-translate-y-1 hover:shadow-[3px_3px_0px_0px_rgba(0,0,0,1)] active:translate-y-0 active:shadow-none transition-all" title="Copy Invite Link">
              <Share2 class="w-4 h-4 text-black" stroke-width="2.5" />
            </button>
            <button @click="leaveRoom" class="px-3 h-10 rounded-xl bg-[#FF458A] border-2 border-black flex items-center gap-2 hover:-translate-y-1 hover:shadow-[3px_3px_0px_0px_rgba(0,0,0,1)] active:translate-y-0 active:shadow-none transition-all">
              <LogOut class="w-4 h-4 text-white" stroke-width="2.5" />
              <span class="text-[11px] font-black uppercase tracking-widest text-white">Cabut</span>
            </button>
          </div>
        </div>
      </header>

      <!-- ========================================== -->
      <!-- MOBILE BOTTOM SHEET & DESKTOP SIDE PANEL   -->
      <!-- ========================================== -->
      <div class="absolute bottom-0 left-0 right-0 md:bottom-8 md:top-8 md:right-8 md:left-auto md:w-[420px] 
                  z-50 pointer-events-auto md:pointer-events-none flex flex-col md:gap-6 mt-auto 
                  transition-all duration-500 ease-in-out
                  bg-white md:bg-transparent border-t-4 border-black md:border-0 rounded-t-3xl md:rounded-none shadow-[0px_-8px_0px_0px_rgba(0,0,0,1)] md:shadow-none"
           :class="[isChatExpanded ? 'h-[85dvh] md:h-auto' : 'h-[170px] md:h-auto']"
           @touchstart="handleTouchStart" @touchend="handleTouchEnd">
        
        <!-- Mobile Drag Handle -->
        <div class="md:hidden w-full h-12 flex flex-col items-center justify-center shrink-0 cursor-pointer group bg-[#FFB800] rounded-t-[calc(1.5rem-4px)] border-b-4 border-black" @click="isChatExpanded = !isChatExpanded">
          <div class="w-12 h-2 bg-black rounded-full transition-transform group-active:scale-x-125"></div>
          <span class="text-[10px] font-black uppercase tracking-[0.2em] text-black mt-1">
             {{ isChatExpanded ? 'Tutup Chat' : 'Obrolan' }}
          </span>
        </div>

        <!-- Desktop Only: Live Pulse Label -->
        <div class="hidden md:flex px-2 items-center gap-2 pointer-events-auto mb-2">
           <span class="px-3 py-1 bg-[#FF458A] border-2 border-black shadow-[2px_2px_0px_0px_rgba(0,0,0,1)] text-[11px] uppercase tracking-widest font-black text-white rotate-2">Tongkrongan</span>
        </div>

        <!-- Feed Container -->
        <div class="flex-1 md:flex-none md:h-[65vh] flex flex-col justify-end md:justify-start relative pointer-events-auto w-full px-4 md:px-0 pt-4 md:pt-0"
             :class="[isChatExpanded ? 'overflow-y-auto' : 'overflow-hidden']">
          
          <div class="flex flex-col gap-4 pb-2 md:pb-0 w-full relative z-10">
            
            <TransitionGroup name="list">
              <div v-for="(item, index) in feed" :key="item.id" 
                   class="p-3 md:p-4 rounded-xl bg-white border-4 border-black shadow-[4px_4px_0px_0px_rgba(0,0,0,1)] hover:-translate-y-1 hover:shadow-[6px_6px_0px_0px_rgba(0,0,0,1)] transition-all"
                   :class="!isChatExpanded && index !== 0 ? 'opacity-0 md:opacity-100 hidden md:flex flex-col' : 'flex flex-col'">
                <div class="flex gap-3 items-start relative overflow-hidden">
                  <div class="w-10 h-10 md:w-12 md:h-12 rounded-lg border-2 border-black shrink-0 overflow-hidden bg-[#00E5FF] p-0.5">
                    <img :src="item.avatar" class="w-full h-full object-cover bg-white" />
                  </div>
                  <div class="flex-1 min-w-0 flex flex-col justify-center pt-0.5">
                    <div class="flex items-center justify-between mb-1">
                      <span class="text-sm font-black text-black truncate">{{ item.name }}</span>
                      <span class="text-[10px] font-bold text-black/40 bg-gray-100 px-1.5 py-0.5 rounded border border-black/20">{{ item.time }}</span>
                    </div>
                    <p class="text-sm text-black font-medium leading-tight line-clamp-2 md:line-clamp-none">{{ item.message }}</p>
                  </div>
                </div>
              </div>
            </TransitionGroup>

            <!-- Empty State -->
            <div v-if="feed.length === 0" class="flex flex-col items-center justify-center py-6">
               <span class="text-sm text-black/50 font-bold bg-gray-100 border-2 border-black/20 border-dashed px-4 py-2 rounded-lg -rotate-2">Belum ada chat.</span>
            </div>

          </div>
        </div>

        <!-- Floating Input / Bottom Input -->
        <div class="w-full shrink-0 px-4 pb-6 pt-2 md:p-0 pointer-events-auto transition-all bg-white md:bg-transparent">
          <div class="bg-white border-4 border-black rounded-xl shadow-[4px_4px_0px_0px_rgba(0,0,0,1)] p-2 flex items-center gap-2">
            <button @click="findMe" class="group relative z-10 w-12 h-12 flex items-center justify-center rounded-lg bg-[#FFB800] border-2 border-black hover:-translate-y-0.5 hover:shadow-[2px_2px_0px_0px_rgba(0,0,0,1)] active:translate-y-0 active:shadow-none transition-all">
              <Crosshair class="w-5 h-5 text-black" stroke-width="2.5" />
            </button>
            <input 
              v-model="statusMessage"
              @keyup.enter="updateStatus"
              type="text" 
              placeholder="Ketik pesan..." 
              class="flex-1 bg-gray-100 border-2 border-black rounded-lg h-12 outline-none px-3 text-sm font-bold text-black placeholder-black/30 focus:bg-white transition-colors"
            />
            <button @click="updateStatus" class="group relative z-10 flex items-center gap-2 px-4 h-12 rounded-lg bg-[#00E5FF] border-2 border-black text-black hover:-translate-y-0.5 hover:shadow-[2px_2px_0px_0px_rgba(0,0,0,1)] active:translate-y-0 active:shadow-none transition-all">
              <span class="text-sm font-black uppercase">Kirim</span>
              <ArrowUpRight class="w-4 h-4 text-black group-hover:translate-x-0.5 group-hover:-translate-y-0.5 transition-transform" stroke-width="3" />
            </button>
          </div>
        </div>

      </div>
    </div>
  </div>
</template>
