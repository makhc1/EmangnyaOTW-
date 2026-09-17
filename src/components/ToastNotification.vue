<script setup>
import { toastState } from '../toast'
import { AlertCircle, CheckCircle2 } from 'lucide-vue-next'
</script>

<template>
  <Transition name="toast">
    <div v-if="toastState" class="fixed top-4 left-1/2 -translate-x-1/2 z-[9999] px-4 w-full max-w-sm pointer-events-none">
      <div class="p-4 rounded-xl border-4 border-black shadow-[4px_4px_0px_0px_rgba(0,0,0,1)] flex items-center gap-3 transition-all"
           :class="toastState.type === 'error' ? 'bg-[#FF458A]' : 'bg-[#00E5FF]'">
        
        <div class="shrink-0 bg-white p-1 rounded-full border-2 border-black">
          <AlertCircle v-if="toastState.type === 'error'" class="w-5 h-5 text-black" stroke-width="2.5" />
          <CheckCircle2 v-else class="w-5 h-5 text-black" stroke-width="2.5" />
        </div>
        
        <span class="text-sm font-bold text-black leading-tight">{{ toastState.message }}</span>
      </div>
    </div>
  </Transition>
</template>

<style>
.toast-enter-active,
.toast-leave-active {
  transition: all 0.4s cubic-bezier(0.32, 0.72, 0, 1);
}
.toast-enter-from,
.toast-leave-to {
  opacity: 0;
  transform: translate(-50%, -20px);
}
</style>
