<script setup>
import { ref, onMounted } from 'vue'
import { v4 as uuidv4 } from 'uuid'
import LobbyView from './components/LobbyView.vue'
import RoomView from './components/RoomView.vue'
import { supabase } from './supabase'

// App State
const view = ref('lobby') // 'lobby' | 'map'
const currentRoomId = ref('')
const currentUser = ref(null)

onMounted(() => {
  // Check URL for shared room code
  const urlParams = new URLSearchParams(window.location.search)
  const sharedRoom = urlParams.get('room')
  if (sharedRoom) {
    currentRoomId.value = sharedRoom
  }
})

const handleJoinRoom = async ({ roomId, nickname, isCreate }) => {
  // Cek kalau nama udah dipakai (khusus pas join room orang lain)
  if (!isCreate) {
    const { data } = await supabase
      .from('members')
      .select('id')
      .eq('room_id', roomId)
      .ilike('nickname', nickname)
      .maybeSingle()
      
    if (data) {
      alert(`Nama '${nickname}' udah ada yang pake di room ini bos, cari nama lain!`)
      return
    }
  }

  currentRoomId.value = roomId
  
  // Update URL so it's shareable
  window.history.pushState({}, '', `?room=${roomId}`)
  
  // Generate a persistent user ID for this session (store in localStorage in a real app)
  let userId = localStorage.getItem('radar_user_id')
  if (!userId) {
    userId = uuidv4()
    localStorage.setItem('radar_user_id', userId)
  }

  currentUser.value = {
    id: userId,
    name: nickname,
    avatar: `https://api.dicebear.com/7.x/avataaars/svg?seed=${nickname}&backgroundColor=transparent`
  }
  
  view.value = 'map'
}

const handleLeaveRoom = () => {
  view.value = 'lobby'
  currentRoomId.value = ''
  window.history.pushState({}, '', window.location.pathname)
}
</script>

<template>
  <div class="h-[100dvh] w-full bg-[#050505] relative overflow-hidden flex flex-col md:flex-row text-white font-sans">
    <!-- Ethereal Noise Overlay (Global) -->
    <div class="pointer-events-none absolute inset-0 z-[100] opacity-[0.03] mix-blend-overlay" style="background-image: url('data:image/svg+xml,%3Csvg viewBox=%220 0 200 200%22 xmlns=%22http://www.w3.org/2000/svg%22%3E%3Cfilter id=%22noiseFilter%22%3E%3CfeTurbulence type=%22fractalNoise%22 baseFrequency=%220.8%22 numOctaves=%223%22 stitchTiles=%22stitch%22/%3E%3C/filter%3E%3Crect width=%22100%25%22 height=%22100%25%22 filter=%22url(%23noiseFilter)%22/%3E%3C/svg%3E');"></div>

    
    <!-- Router alternative using conditional rendering -->
    <LobbyView 
      v-if="view === 'lobby'" 
      :initial-room-id="currentRoomId"
      @join="handleJoinRoom" 
    />
    
    <RoomView 
      v-else-if="view === 'map'"
      :room-id="currentRoomId"
      :user="currentUser"
      @leave="handleLeaveRoom"
    />
  </div>
</template>
