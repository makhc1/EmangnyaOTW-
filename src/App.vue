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
    avatar: `https://api.dicebear.com/9.x/pixel-art/svg?seed=${nickname}&backgroundColor=b6e3f4,c0aede,d1d4f9`
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
  <div class="h-[100dvh] w-full bg-[#f4f4f0] relative overflow-hidden flex flex-col md:flex-row text-black font-sans selection:bg-pink-400 selection:text-white">
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
