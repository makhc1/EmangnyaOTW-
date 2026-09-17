<script setup>
import { ref, onMounted } from 'vue'
import { Bike, Users, KeyRound, ArrowRight } from 'lucide-vue-next'
import { v4 as uuidv4 } from 'uuid'
import { showToast } from '../toast'

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
    showToast("Isi nama/nickname dulu bos!", 'error')
    return
  }
  
  if (isCreate) {
    roomId.value = uuidv4()
  } else if (!roomId.value.trim()) {
    showToast("Isi PIN Room dulu!", 'error')
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
  <!-- Decorative Background Shapes -->
  <div class="fixed inset-0 pointer-events-none overflow-hidden z-0">
    <!-- Circle -->
    <div class="absolute top-[-10%] right-[-5%] w-[40vw] h-[40vw] rounded-full bg-[#FF458A] border-[8px] border-black opacity-20 rotate-12"></div>
    <!-- Star / Polygon -->
    <div class="absolute bottom-[5%] left-[-10%] w-[50vw] h-[50vw] bg-[#00E5FF] border-[8px] border-black opacity-20 transform -rotate-12" style="clip-path: polygon(50% 0%, 61% 35%, 98% 35%, 68% 57%, 79% 91%, 50% 70%, 21% 91%, 32% 57%, 2% 35%, 39% 35%);"></div>
  </div>

  <div class="relative z-10 w-full h-full flex flex-col items-center justify-center p-6">
    <div class="w-full max-w-sm transform transition-all duration-500"
         :class="isLoaded ? 'translate-y-0 opacity-100' : 'translate-y-12 opacity-0'">
      
      <!-- Branding -->
      <div class="flex flex-col items-center gap-2 mb-10">
        <div class="w-20 h-20 rounded-2xl bg-[#FFB800] border-4 border-black shadow-[6px_6px_0px_0px_rgba(0,0,0,1)] flex items-center justify-center rotate-3 hover:rotate-6 transition-transform">
           <Bike class="w-10 h-10 text-black" stroke-width="2.5" />
        </div>
        <div class="text-center mt-4">
          <h1 class="text-4xl font-black tracking-tight text-black uppercase" style="text-shadow: 2px 2px 0px #FF458A, 4px 4px 0px #000;">EMANGNYA OTW?</h1>
          <p class="text-xs font-bold text-black mt-2 bg-[#00E5FF] inline-block px-3 py-1.5 border-2 border-black -rotate-2">Pantau temen lu yang ngakunya udah di jalan.</p>
        </div>
      </div>

      <!-- Main Panel -->
      <div class="bg-white border-4 border-black p-6 rounded-2xl shadow-[8px_8px_0px_0px_rgba(0,0,0,1)] flex flex-col gap-6 relative z-10">
        
        <!-- Nickname Input -->
        <div class="space-y-2">
          <label class="text-sm font-bold uppercase tracking-wider text-black flex items-center gap-2">
             <span class="w-2 h-2 bg-[#FF458A] rounded-full border border-black"></span> Nama Lu Siapa?
          </label>
          <div class="h-14 bg-[#f4f4f0] border-4 border-black rounded-xl flex items-center px-4 focus-within:-translate-y-1 focus-within:shadow-[4px_4px_0px_0px_rgba(0,0,0,1)] transition-all">
            <Users class="w-5 h-5 text-black mr-3 shrink-0" stroke-width="2" />
            <input v-model="nickname" @keyup.enter="roomId ? joinRoom() : joinRoom(true)" type="text" placeholder="Ketik nama panggilan..." class="flex-1 bg-transparent border-none outline-none text-lg font-bold text-black placeholder-black/30" />
          </div>
        </div>

        <template v-if="!props.initialRoomId">
          <!-- Join Existing Room -->
          <div class="space-y-2">
             <label class="text-sm font-bold uppercase tracking-wider text-black flex items-center gap-2">
               <span class="w-2 h-2 bg-[#00E5FF] rounded-full border border-black"></span> Masuk Room
            </label>
            <div class="flex gap-2">
              <div class="flex-1 h-14 bg-[#f4f4f0] border-4 border-black rounded-xl flex items-center px-4 focus-within:-translate-y-1 focus-within:shadow-[4px_4px_0px_0px_rgba(0,0,0,1)] transition-all">
                <KeyRound class="w-5 h-5 text-black mr-3 shrink-0" stroke-width="2" />
                <input v-model="roomId" @keyup.enter="joinRoom()" type="text" placeholder="Tempel Link / PIN" class="flex-1 w-full bg-transparent border-none outline-none text-base font-bold text-black placeholder-black/30" />
              </div>
              <button v-if="roomId" @click="joinRoom()" class="h-14 px-5 border-4 border-black rounded-xl bg-[#00E5FF] text-black font-black text-lg hover:-translate-y-1 hover:shadow-[4px_4px_0px_0px_rgba(0,0,0,1)] active:translate-y-0 active:shadow-none transition-all flex items-center justify-center">
                GO
              </button>
            </div>
          </div>

          <div class="relative py-2 flex items-center justify-center">
            <div class="absolute inset-0 flex items-center">
              <div class="w-full border-t-4 border-black border-dashed"></div>
            </div>
            <span class="relative bg-white px-4 text-xs font-black uppercase text-black">ATAU</span>
          </div>

          <!-- Create Room Button -->
          <button @click="joinRoom(true)" class="group w-full h-16 border-4 border-black rounded-xl bg-[#FFB800] text-black hover:-translate-y-1 hover:shadow-[6px_6px_0px_0px_rgba(0,0,0,1)] active:translate-y-0 active:shadow-none transition-all flex items-center justify-center gap-3">
            <span class="text-lg font-black uppercase tracking-wide">Bikin Room Baru</span>
            <ArrowRight class="w-6 h-6 text-black group-hover:translate-x-1 transition-transform" stroke-width="3" />
          </button>
        </template>
        
        <template v-else>
          <!-- Invited User Mode -->
          <button @click="joinRoom()" class="group w-full h-16 border-4 border-black rounded-xl bg-[#00E5FF] text-black hover:-translate-y-1 hover:shadow-[6px_6px_0px_0px_rgba(0,0,0,1)] active:translate-y-0 active:shadow-none transition-all flex items-center justify-center gap-3 mt-2">
            <span class="text-lg font-black uppercase tracking-wide">Langsung Masuk</span>
            <ArrowRight class="w-6 h-6 text-black group-hover:translate-x-1 transition-transform" stroke-width="3" />
          </button>
        </template>

      </div>
    </div>
  </div>
</template>
