import { ref } from 'vue'

export const toastState = ref(null)

export const showToast = (message, type = 'error') => {
  toastState.value = { message, type }
  setTimeout(() => {
    // Only clear if it's the same message (prevents fast clicking bugs)
    if (toastState.value && toastState.value.message === message) {
      toastState.value = null
    }
  }, 3500)
}
