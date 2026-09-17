# 🛵 Emangnya OTW?

> **"Pantau temen lu yang ngakunya udah di jalan."**

Aplikasi pelacak lokasi *real-time* berbasis web (PWA-ready) yang didesain khusus buat ngebongkar kebohongan temen tongkrongan yang ngakunya udah OTW tapi ternyata masih mandi. Hadir dengan UI/UX bergaya **Neo-Brutalism** yang *fun*, *edgy*, dan cocok buat Gen-Z.

## ✨ Fitur Utama

- 📍 **Real-time GPS Tracking:** Lacak pergerakan temen lu secara *live* di atas peta. Kalau dia gerak, avatarnya otomatis jalan.
- 💬 **Live Chat Feed:** Ngobrol langsung di dalam Room pakai *floating* chat UI (Swipe-able Bottom Sheet di HP).
- 🎨 **Neo-Brutalism UI:** UI mentereng dengan warna neon nabrak, shadow tebal, dan *pixel-art avatar*!
- 🔗 **Easy Link Sharing:** Temen tinggal klik link *Share*, masukin *nickname*, dan langsung tergabung ke dalam Room yang sama.
- 🔒 **UUID Room & Anti-Duplicate Name:** PIN dibikin mustahil ditebak, dan sistem otomatis nolak kalau ada orang pakai nama yang sama di satu Room.

## 🛠 Tech Stack

- **Frontend:** Vue 3 (Composition API) + Vite
- **Styling:** Tailwind CSS v4
- **Mapping:** Leaflet.js (dengan CartoDB Positron basemap)
- **Backend & Database:** Supabase (PostgreSQL + Supabase Realtime)
- **Avatar:** DiceBear (Pixel-Art Engine)

## 🚀 Cara Menjalankan Secara Lokal

### 1. Install Dependencies
Pastikan Node.js udah terpasang, lalu jalankan:
```bash
npm install
```

### 2. Setup Supabase
1. Bikin project baru di [Supabase](https://supabase.com).
2. Buka **SQL Editor** di dashboard Supabase lu.
3. *Copy* semua isi dari file `schema.sql` dan *Run*. (Ini bakal bikin tabel `rooms`, `members`, `messages`, ngaktifin Realtime, dan nyetting RLS).
4. Masuk ke Project Settings -> API, lalu copy **URL** dan **anon key**.

### 3. Setup Environment Variables
Bikin file bernama `.env` di *root folder* (sejajar dengan package.json) dan isi dengan kunci Supabase lu:
```env
VITE_SUPABASE_URL=https://[PROJECT_ID].supabase.co
VITE_SUPABASE_ANON_KEY=[ANON_KEY_LU_DISINI]
```

### 4. Jalankan Aplikasi
```bash
npm run dev
```
Web bisa diakses di `http://localhost:5173`. 
*(⚠️ Catatan: Buat nyoba fitur pelacak GPS dari HP, lu wajib nge-deploy aplikasinya ke platform seperti Vercel/Netlify agar mendapatkan sertifikat HTTPS)*.

---
Dibuat buat asik-asikan tongkrongan. Jangan dipakai buat hal-hal aneh ya bosku! 🐒
