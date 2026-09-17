Gunakan Bahasa Indonesia untuk seluruh respons, laporan status, pertanyaan, penjelasan, dan ringkasan akhir. Pertahankan nama tool, path, perintah, serta key konfigurasi apa adanya.

Siapkan dan gunakan DesainPakeAI CLI untuk project ini. Cek apakah CLI sudah tersedia sebelum menginstal, lalu konfirmasi project aktif dan ambil context terbaru sebelum membuat perubahan.

Gunakan instalasi global agar perintah DesainPakeAI berikutnya berjalan cepat. Jalankan setiap operasi dengan:
`dpai`

Kerjakan setup CLI sekarang:
1. Cek terlebih dahulu apakah CLI tersedia dengan `dpai --version`. Jangan langsung menginstal.
2. Jika perintah tersebut tidak tersedia, instal dengan `npm install --global desainpakeai-cli@latest`, lalu ulangi cek versi.
3. Pasang atau perbarui skill DesainPakeAI dan simpan access key ke konfigurasi user dengan `npx @desainpakeai/skills --api-key dpai_64qVTZ0iVGiyJZVh2RVOZJf5orgQt16R27LWw0vYbIQ`. Command ini aman dijalankan ulang saat setup; jangan menjalankannya pada setiap task.
4. Pastikan environment `DPAI_AGENT_HARNESS` berisi nama harness yang sedang digunakan (misalnya `codex`, `claude-code`, atau nama client sendiri). Tetapkan hanya bila CLI belum dapat mendeteksinya otomatis.
5. Jalankan `dpai auth login --api-url https://desainpakeai.com --api-key dpai_64qVTZ0iVGiyJZVh2RVOZJf5orgQt16R27LWw0vYbIQ`.
6. Verifikasi sesi dengan `dpai auth status --pretty`.
7. Konfirmasi target memakai `dpai project current --pretty`. Project aktif harus sama dengan project yang diminta.
8. Ambil konteks terbaru memakai `dpai context --pretty`, lalu simpan revision yang dikembalikan.
9. Jalankan seluruh operasi DesainPakeAI berikutnya melalui `dpai`. Jangan menginisialisasi atau memakai server MCP DesainPakeAI.

Setup selesai setelah versi CLI, ketersediaan skill, auth status, project current, dan context berhasil dikonfirmasi. Skill global berlaku untuk task agent berikutnya; lanjutkan task saat ini memakai instruksi dalam prompt ini. Jika salah satu perintah gagal, laporkan perintah dan pesan error-nya tanpa mengaku setup sudah selesai.

Jika instalasi CLI gagal dengan `EEXIST` pada binary `dpai`, hapus paket beta lama memakai `npm uninstall --global @desainpakeai/cli`, lalu ulangi langkah 1. Jangan gunakan `--force`.

Gunakan API key ini hanya untuk origin DesainPakeAI yang tercantum di bawah. API key tetap aktif sampai dicabut dan tidak memerlukan refresh token. Jangan pernah memasukkannya ke URL atau commit repository.