<script setup>
import { ref, onMounted } from 'vue'
import { Radar, Users, KeyRound, ArrowUpRight } from 'lucide-vue-next'

import { v4 as uuidv4 } from 'uuid'

const props = defineProps({
  initialRoomId: String
})

const emit = defineEmits(['join'])

const isLoaded = ref(false)
const roomId = ref(props.initialRoomId || '')
const nickname = ref('')

onMounted(() => {
  setTimeout(() => {
    isLoaded.value = true
  }, 100)
})

const joinRoom = (isCreate = false) => {
  if (!nickname.value.trim()) {
    alert("Isi nama/nickname dulu bos!")
    return
  }
  
  if (isCreate) {
    roomId.value = uuidv4()
  } else if (!roomId.value.trim()) {
    alert("Isi PIN Room dulu!")
    return
  }

  emit('join', {
    roomId: roomId.value,
    nickname: nickname.value,
    isCreate
  })
}
</script>

<template>
  <div class="relative z-10 w-full h-full flex flex-col items-center justify-center p-4">
    <!-- Background Ambient Glow -->
    <div class="absolute inset-0 z-0 flex items-center justify-center opacity-30 pointer-events-none">
      <div class="w-[40vw] h-[40vw] bg-white rounded-full blur-[120px] opacity-10 mix-blend-screen"></div>
    </div>

    <div class="relative z-10 w-full max-w-sm transform transition-all duration-fluid ease-fluid"
         :class="isLoaded ? 'translate-y-0 opacity-100 blur-0' : 'translate-y-12 opacity-0 blur-md'">
      
      <!-- Branding -->
      <div class="flex flex-col items-center gap-4 mb-12">
        <div class="w-16 h-16 rounded-full bg-white/5 flex items-center justify-center ring-1 ring-white/10 shadow-[inset_0_1px_1px_rgba(255,255,255,0.05)] relative overflow-hidden group">
           <div class="absolute inset-0 bg-gradient-to-br from-white/10 to-transparent opacity-0 group-hover:opacity-100 transition-opacity duration-500"></div>
           <Radar class="w-8 h-8 text-white/90 relative z-10" stroke-width="1" />
        </div>
        <div class="text-center">
          <h1 class="text-2xl font-semibold tracking-[0.2em] text-white uppercase mb-1">Radar Nongki</h1>
          <p class="text-sm font-light text-white/40 tracking-wide">Sync your circle. Real-time.</p>
        </div>
      </div>

      <!-- Double Bezel Form Panel -->
      <div class="p-[5px] rounded-[2.5rem] bg-white/[0.02] ring-1 ring-white/10 backdrop-blur-3xl shadow-2xl">
        <div class="p-6 rounded-[calc(2.5rem-5px)] bg-[#0a0a0a]/80 shadow-[inset_0_1px_1px_rgba(255,255,255,0.05)] flex flex-col gap-6">
          
          <!-- Nickname Input -->
          <div class="space-y-2">
            <label class="text-[10px] font-medium uppercase tracking-[0.2em] text-white/50 ml-2">Who are you?</label>
            <div class="h-12 rounded-2xl bg-white/5 ring-1 ring-white/10 flex items-center px-4 focus-within:ring-white/30 transition-all">
              <Users class="w-4 h-4 text-white/40 mr-3 shrink-0" stroke-width="1.5" />
              <input v-model="nickname" @keyup.enter="roomId ? joinRoom() : joinRoom(true)" type="text" placeholder="Enter nickname..." class="flex-1 bg-transparent border-none outline-none text-[15px] font-light text-white placeholder-white/20" />
            </div>
          </div>

          <div class="w-full h-[1px] bg-white/5"></div>

          <!-- Action Area -->
          <div class="space-y-4">
            <!-- Join Existing Room -->
            <div class="flex gap-2">
              <div class="flex-1 h-12 rounded-2xl bg-white/5 ring-1 ring-white/10 flex items-center px-4 focus-within:ring-white/30 transition-all">
                <KeyRound class="w-4 h-4 text-white/40 mr-3 shrink-0" stroke-width="1.5" />
                <input v-model="roomId" @keyup.enter="joinRoom()" type="text" placeholder="Room PIN (Optional)" class="flex-1 bg-transparent border-none outline-none text-[15px] font-light uppercase text-white placeholder-white/20" />
              </div>
              <button v-if="roomId" @click="joinRoom()" class="h-12 px-6 rounded-2xl bg-white text-black font-semibold text-sm hover:bg-gray-100 transition-all active:scale-[0.96]">
                Join
              </button>
            </div>

            <div class="text-center text-[10px] font-medium text-white/30 uppercase tracking-[0.1em] flex items-center gap-2">
              <span class="flex-1 h-[1px] bg-white/5"></span>
              <span>OR</span>
              <span class="flex-1 h-[1px] bg-white/5"></span>
            </div>

            <!-- Create Room Button -->
            <button @click="joinRoom(true)" class="group w-full h-12 rounded-2xl bg-white/[0.03] hover:bg-white/[0.06] ring-1 ring-white/10 flex items-center justify-center gap-2 transition-all active:scale-[0.98]">
              <span class="text-[13px] font-semibold tracking-wide text-white/80">Create New Room</span>
              <div class="w-6 h-6 rounded-full bg-white/10 flex items-center justify-center transition-transform duration-500 ease-fluid group-hover:translate-x-1">
                <ArrowUpRight class="w-3 h-3 text-white" stroke-width="2" />
              </div>
            </button>
          </div>

        </div>
      </div>
    </div>
  </div>
</template>
