<script setup>
import { ref, onMounted, onUnmounted, nextTick } from 'vue'
import L from 'leaflet'
import 'leaflet/dist/leaflet.css'
import { Radar, Crosshair, ArrowUpRight, Share2, LogOut, ChevronUp, ChevronDown } from 'lucide-vue-next'
import { supabase } from '../supabase'

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
  alert('Share link copied to clipboard!')
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

  const { error: memberErr } = await supabase
    .from('members')
    .upsert([{ 
      id: props.user.id, 
      room_id: props.roomId, 
      nickname: props.user.name, 
      avatar_url: props.user.avatar,
      last_updated: new Date().toISOString()
    }])

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
const updateMapMarkers = () => {
  if (!map.value) return

  members.value.forEach(m => {
    if (!m.lat || !m.lng) return

    const isMe = m.id === props.user.id
    const avatarHtml = isMe 
      ? `
      <div class="relative group">
        <div class="absolute -inset-2 bg-white/20 rounded-full blur-md animate-pulse"></div>
        <div class="relative w-12 h-12 rounded-full ring-2 ring-white/50 bg-[#0a0a0a] shadow-2xl overflow-hidden flex items-center justify-center p-0.5">
           <img src="${m.avatar_url}" class="w-full h-full object-cover rounded-full bg-white/5" />
        </div>
      </div>
      `
      : `
      <div class="w-10 h-10 rounded-full ring-1 ring-white/20 bg-[#111] shadow-xl overflow-hidden flex items-center justify-center p-0.5 opacity-80 hover:opacity-100 transition-opacity">
        <img src="${m.avatar_url}" class="w-full h-full object-cover rounded-full bg-white/5" />
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
      },
      { enableHighAccuracy: true, maximumAge: 10000, timeout: 5000 }
    )
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

  // Pakai CartoDB Gratisan (Watermark udah dimatiin)
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
  <div class="absolute inset-0 z-0">
    <!-- Map Canvas -->
    <div ref="mapContainer" class="absolute inset-0 z-0"></div>

    <!-- Main Content Wrapper -->
    <div class="relative z-10 w-full h-full pointer-events-none flex flex-col justify-between p-4 md:p-8">
      
      <!-- Top Nav Island (Always visible) -->
      <header class="w-full max-w-sm mx-auto md:mx-0 md:max-w-md pointer-events-auto transform transition-all duration-fluid ease-fluid">
        <div class="p-[5px] rounded-full bg-white/[0.02] ring-1 ring-white/10 backdrop-blur-3xl shadow-2xl">
          <div class="px-3 py-2 rounded-[calc(9999px-5px)] bg-[#0a0a0a]/70 shadow-[inset_0_1px_1px_rgba(255,255,255,0.05)] flex items-center justify-between">
            <div class="flex items-center gap-3 pl-2">
              <Radar class="w-5 h-5 text-white/80" stroke-width="1.25" />
              <div class="flex flex-col">
                 <h1 class="text-[11px] font-semibold tracking-[0.1em] text-white/90 uppercase">Room</h1>
                 <span class="text-[10px] text-white/50 tracking-widest">{{ roomId }}</span>
              </div>
            </div>
            <div class="flex items-center gap-2">
              <button @click="copyShareLink" class="w-8 h-8 rounded-full bg-white/5 hover:bg-white/10 ring-1 ring-white/10 flex items-center justify-center transition-all active:scale-95" title="Copy Invite Link">
                <Share2 class="w-3.5 h-3.5 text-white/80" stroke-width="1.5" />
              </button>
              <div class="w-[1px] h-4 bg-white/10"></div>
              <button @click="leaveRoom" class="px-3 py-1.5 rounded-full bg-red-500/10 hover:bg-red-500/20 ring-1 ring-red-500/20 flex items-center gap-2 transition-all active:scale-95">
                <LogOut class="w-3.5 h-3.5 text-red-400" stroke-width="1.5" />
                <span class="text-[10px] font-bold uppercase tracking-widest text-red-400">Leave</span>
              </button>
            </div>
          </div>
        </div>
      </header>

      <!-- ========================================== -->
      <!-- MOBILE BOTTOM SHEET & DESKTOP SIDE PANEL   -->
      <!-- ========================================== -->
      <!-- 
        Mobile behavior: absolute bottom, takes full width, collapses to 180px, expands to 85dvh.
        Desktop behavior: absolute right side, 420px width, flex layout, always fully expanded.
      -->
      <div class="absolute bottom-0 left-0 right-0 md:bottom-8 md:top-8 md:right-8 md:left-auto md:w-[420px] 
                  z-50 pointer-events-auto md:pointer-events-none flex flex-col md:gap-6 mt-auto 
                  transition-all duration-fluid ease-fluid
                  bg-[#0a0a0a]/90 md:bg-transparent backdrop-blur-3xl md:backdrop-blur-none 
                  rounded-t-[2rem] md:rounded-none ring-1 md:ring-0 ring-white/10"
           :class="[isChatExpanded ? 'h-[85dvh] md:h-auto' : 'h-[170px] md:h-auto']"
           @touchstart="handleTouchStart" @touchend="handleTouchEnd">
        
        <!-- Mobile Drag Handle -->
        <div class="md:hidden w-full h-10 flex flex-col items-center justify-center shrink-0 cursor-pointer group" @click="isChatExpanded = !isChatExpanded">
          <div class="w-12 h-1.5 bg-white/20 rounded-full transition-colors group-active:bg-white/40"></div>
          <span class="text-[9px] font-medium uppercase tracking-[0.2em] text-white/30 mt-1">
             {{ isChatExpanded ? 'Swipe Down' : 'Live Pulse' }}
          </span>
        </div>

        <!-- Desktop Only: Live Pulse Label -->
        <div class="hidden md:flex px-2 items-center gap-2 pointer-events-auto">
           <span class="px-3 py-1 rounded-full bg-white/5 ring-1 ring-white/10 text-[10px] uppercase tracking-[0.2em] font-medium text-white/50 backdrop-blur-md">Live Pulse</span>
        </div>

        <!-- Feed Container -->
        <div class="flex-1 md:flex-none md:h-[65vh] flex flex-col justify-end md:justify-start relative pointer-events-auto w-full px-4 md:px-0"
             :class="[isChatExpanded ? 'overflow-y-auto' : 'overflow-hidden']">
          
          <div class="flex flex-col gap-3 pb-2 md:pb-0 px-1 w-full relative z-10 transition-transform duration-fluid ease-fluid"
               :class="!isChatExpanded && feed.length > 0 ? 'translate-y-0' : 'translate-y-0'">
            
            <TransitionGroup name="list">
              <div v-for="(item, index) in feed" :key="item.id" 
                   class="p-[5px] rounded-[1.5rem] md:rounded-[2rem] bg-white/[0.02] ring-1 ring-white/10 backdrop-blur-2xl shadow-2xl transition-all duration-fluid ease-fluid hover:bg-white/[0.04]"
                   :class="!isChatExpanded && index !== 0 ? 'opacity-0 md:opacity-100 hidden md:block' : ''">
                <div class="p-4 md:p-5 rounded-[calc(1.5rem-5px)] md:rounded-[calc(2rem-5px)] bg-[#0a0a0a]/80 shadow-[inset_0_1px_1px_rgba(255,255,255,0.05)] flex gap-4 items-start relative overflow-hidden group">
                  <div class="absolute inset-0 bg-gradient-to-br from-white/[0.03] to-transparent opacity-0 group-hover:opacity-100 transition-opacity duration-500 ease-fluid pointer-events-none"></div>
                  <div class="w-8 h-8 md:w-10 md:h-10 rounded-full ring-1 ring-white/20 shrink-0 overflow-hidden bg-[#111] p-0.5 relative z-10">
                    <img :src="item.avatar" class="w-full h-full object-cover rounded-full bg-white/5" />
                  </div>
                  <div class="flex-1 min-w-0 flex flex-col justify-center relative z-10 pt-0.5">
                    <div class="flex items-center justify-between mb-1">
                      <span class="text-[13px] md:text-[14px] font-semibold text-white/90 truncate tracking-wide">{{ item.name }}</span>
                      <span class="text-[9px] md:text-[10px] font-medium text-white/40 tracking-widest uppercase">{{ item.time }}</span>
                    </div>
                    <p class="text-[12px] md:text-[13px] text-white/60 leading-relaxed font-light line-clamp-2 md:line-clamp-none">{{ item.message }}</p>
                  </div>
                </div>
              </div>
            </TransitionGroup>

            <!-- Empty State -->
            <div v-if="feed.length === 0" class="flex flex-col items-center justify-center py-6 opacity-50">
               <span class="text-xs text-white font-light">No pulse yet. Say something.</span>
            </div>

          </div>
        </div>

        <!-- Floating Input / Bottom Input -->
        <!-- On mobile, it's pinned to the bottom of the sheet. On desktop, it's floating. -->
        <div class="w-full shrink-0 px-4 pb-6 pt-2 md:p-0 pointer-events-auto transition-all duration-fluid ease-fluid bg-[#0a0a0a] md:bg-transparent">
          <div class="p-[5px] rounded-[1.5rem] md:rounded-[2rem] bg-white/[0.02] ring-1 ring-white/10 backdrop-blur-3xl shadow-2xl">
            <div class="p-1.5 md:p-2 rounded-[calc(1.5rem-5px)] md:rounded-[calc(2rem-5px)] bg-[#0a0a0a]/80 shadow-[inset_0_1px_1px_rgba(255,255,255,0.05)] flex items-center gap-2 relative overflow-hidden">
              <button @click="findMe" class="group relative z-10 w-10 h-10 md:w-12 md:h-12 flex items-center justify-center rounded-[calc(1.5rem-12px)] md:rounded-[calc(2rem-12px)] bg-white/5 hover:bg-white/10 ring-1 ring-white/5 transition-all duration-500 ease-fluid active:scale-[0.96]">
                <Crosshair class="w-[16px] h-[16px] md:w-[18px] md:h-[18px] text-white/50 group-hover:text-white transition-colors" stroke-width="1.25" />
              </button>
              <div class="w-[1px] h-6 md:h-8 bg-white/10 relative z-10"></div>
              <input 
                v-model="statusMessage"
                @keyup.enter="updateStatus"
                type="text" 
                placeholder="Send pulse..." 
                class="flex-1 relative z-10 bg-transparent border-none outline-none px-2 text-[13px] md:text-[14px] text-white placeholder-white/30 font-light"
              />
              <button @click="updateStatus" class="group relative z-10 flex items-center gap-2 md:gap-3 pl-4 pr-1.5 py-1.5 md:pl-5 rounded-[calc(1.5rem-12px)] md:rounded-[calc(2rem-12px)] bg-white text-black hover:bg-gray-100 transition-all duration-500 ease-fluid active:scale-[0.96] shadow-[0_0_20px_rgba(255,255,255,0.1)]">
                <span class="text-[12px] md:text-[13px] font-semibold tracking-wide">Send</span>
                <div class="w-7 h-7 md:w-9 md:h-9 rounded-[calc(1.5rem-18px)] md:rounded-[calc(2rem-18px)] bg-black/5 flex items-center justify-center transition-transform duration-500 ease-fluid group-hover:translate-x-[2px] group-hover:scale-[1.05] group-active:translate-x-0">
                  <ArrowUpRight class="w-[14px] h-[14px] md:w-[18px] md:h-[18px] text-black" stroke-width="1.5" />
                </div>
              </button>
            </div>
          </div>
        </div>

      </div>
    </div>
  </div>
</template>
