# 🗺️ CashWay — Roadmap Pengembangan

**Versi Target:** 1.0  
**Estimasi Total:** 8 Minggu  
**Tech Stack:** Swift 6.3.3 · SwiftUI · SwiftData · Xcode 26.6  

---

## 🔭 Visi Jangka Panjang

```
v1.0 → MVP (offline, macOS + iOS)
v1.1 → iCloud Sync + Widget iOS
v1.2 → Recurring Transactions + PDF Export
v2.0 → Import CSV Rekening Koran + Advanced Analytics
```

---

## 📅 Phase 1 — Foundation & Setup (Minggu 1)

**Goal:** Project bisa dibuild dan jalan di MacBook + iPhone

### Tasks
- [ ] Buat project Xcode multi-platform (macOS + iOS target)
- [ ] Setup SwiftData stack (ModelContainer, ModelContext)
- [ ] Define semua data models:
  - `Transaction.swift`
  - `Category.swift`
  - `Wallet.swift`
  - `Budget.swift`
- [ ] Setup navigation structure (TabView)
- [ ] Setup color palette & design tokens di `Assets.xcassets`
- [ ] Setup SF Symbol library untuk icons
- [ ] Seed data kategori default (14 expense + 6 income)
- [ ] Test build di MacBook dan iPhone 13

### Deliverable
✅ App terbuka di kedua device dengan UI skeleton (kosong tapi berfungsi)

---

## 📅 Phase 2 — Core CRUD Transaksi (Minggu 2-3)

**Goal:** User bisa mencatat dan melihat transaksi

### Minggu 2 — Input Transaksi
- [ ] Screen: Add Transaction (bottom sheet / full screen)
  - Amount input (numpad style, format Rupiah otomatis)
  - Type toggle: Pengeluaran / Pemasukan
  - Category picker (grid dengan icon)
  - Wallet picker
  - Date picker
  - Note field
- [ ] Simpan ke SwiftData
- [ ] Validasi input (jumlah > 0, kategori dipilih, dll)

### Minggu 3 — Riwayat & Edit
- [ ] Screen: Transaction List
  - Grouped by date
  - Tampil icon kategori, jumlah (merah/hijau), catatan
- [ ] Edit transaksi (swipe-to-edit atau tap)
- [ ] Delete transaksi (swipe-to-delete dengan konfirmasi)
- [ ] Filter: by kategori, by tipe, by rentang tanggal
- [ ] Search transaksi by catatan/kategori

### Deliverable
✅ User bisa input, edit, hapus, dan cari transaksi

---

## 📅 Phase 3 — Dashboard & Visualisasi (Minggu 4)

**Goal:** User bisa melihat kondisi keuangan sekilas

### Tasks
- [ ] Screen: Dashboard (Home)
  - Greeting + tanggal hari ini
  - Card: Saldo Total (semua wallet)
  - Card: Pemasukan bulan ini (hijau)
  - Card: Pengeluaran bulan ini (merah)
  - Bar chart: Pengeluaran 30 hari terakhir (Swift Charts)
  - Pie chart / donut chart: Distribusi per kategori
  - Recent transactions (5 terakhir)
- [ ] Month switcher (navigasi bulan)
- [ ] Animasi chart yang smooth

### Deliverable
✅ Dashboard visual dengan data real dari transaksi yang dicatat

---

## 📅 Phase 4 — Wallet & Budget (Minggu 5)

**Goal:** User bisa kelola dompet dan set anggaran

### Wallet Management
- [ ] Screen: Wallet List
  - Card per wallet: nama, tipe, saldo saat ini
  - Warna custom per wallet
- [ ] Add / Edit / Delete wallet
- [ ] Screen: Transfer antar wallet
- [ ] Saldo wallet auto-update dari transaksi

### Budget Management
- [ ] Screen: Budget List
  - Per kategori: batas budget vs pengeluaran (progress bar)
  - Warning visual jika > 80%
  - Danger visual jika > 100%
- [ ] Set budget per kategori per bulan
- [ ] In-app notification saat mendekati limit

### Deliverable
✅ Multi-wallet dan sistem budget berjalan

---

## 📅 Phase 5 — Kategori Custom & Settings (Minggu 6)

**Goal:** Personalisasi aplikasi

### Custom Category
- [ ] Add kategori baru (nama + icon SF Symbol + warna)
- [ ] Edit kategori existing
- [ ] Soft-delete kategori (tidak bisa hapus jika sudah dipakai transaksi)

### Settings Screen
- [ ] Profil: nama pengguna (dipakai di greeting)
- [ ] Notifikasi budget: on/off
- [ ] iCloud Sync: toggle on/off
- [ ] Export data (JSON backup)
- [ ] Tentang aplikasi (versi, credits)
- [ ] Hapus semua data (dengan konfirmasi)

### Deliverable
✅ App bisa dipersonalisasi sepenuhnya

---

## 📅 Phase 6 — Laporan & Export (Minggu 7)

**Goal:** User bisa lihat & simpan laporan

### Tasks
- [ ] Screen: Reports
  - Tab: Bulanan, Mingguan, Kategori
  - Tabel ringkasan per kategori (jumlah transaksi, total)
  - Tren pengeluaran (line chart per bulan)
- [ ] Export ke PDF:
  - Layout PDF: logo CashWay, periode, tabel transaksi, ringkasan
  - Save ke Files app / share sheet
- [ ] iCloud Sync implementation (CloudKit + SwiftData)

### Deliverable
✅ Laporan visual + PDF export + iCloud sync bekerja

---

## 📅 Phase 7 — Polish, Testing & Deploy (Minggu 8)

**Goal:** App siap dipakai sehari-hari

### UI/UX Polish
- [ ] Animasi transisi antar screen (smooth)
- [ ] Haptic feedback di action penting
- [ ] Empty states (jika belum ada transaksi)
- [ ] Loading states
- [ ] Error handling yang user-friendly
- [ ] Adaptive layout macOS (sidebar + detail pane)

### Testing
- [ ] Manual testing semua fitur di iPhone 13
- [ ] Manual testing di MacBook
- [ ] Test iCloud sync (edit di Mac, cek di iPhone)
- [ ] Test edge cases (jumlah sangat besar, kategori kosong, dll)
- [ ] Performance test (1000+ transaksi)

### Deploy Final
- [ ] Set app icon (1024x1024 + semua ukuran)
- [ ] App name: "CashWay"
- [ ] Bundle ID: `com.wahyuahmad.cashway`
- [ ] Install final ke iPhone via Xcode
- [ ] Install di MacBook (run from Xcode atau export .app)

### Deliverable
✅ CashWay v1.0 berjalan di iPhone 13 + MacBook

---

## 🚧 Backlog (v1.1+)

| Fitur | Estimasi |
|-------|----------|
| iOS Widget (saldo + quick add) | 1 minggu |
| Recurring transactions (cicilan, langganan) | 1 minggu |
| Import CSV rekening koran | 2 minggu |
| Siri Shortcut "Tambah pengeluaran Rp X" | 1 minggu |
| Face ID / Touch ID lock | 3 hari |
| macOS Menu Bar widget | 1 minggu |

---

## 📊 Progress Tracker

| Phase | Status | Update Terakhir |
|-------|--------|-----------------|
| Phase 1: Foundation (UI/UX) | ✅ Selesai | UI Dark Mode (Copilot Style) |
| Phase 2: CRUD Transaksi | ✅ Selesai | Menyimpan & filter transaksi |
| Phase 3: Dashboard & AI Advice | ✅ Selesai | Auto-budget & Smart Advice |
| Phase 4: Tabungan & Budget | ✅ Selesai | Progress tabungan & limit budget |
| Phase 5: Migrasi Firebase | ✅ Selesai | Data realtime via Firestore (Cloud Sync) |
| Phase 6: Autentikasi Google | ✅ Selesai | Google Sign-In macOS & iOS via Firebase Auth |
| Phase 7: UI Polish & Bug Fixes | ✅ Selesai | Animasi SlideInCard, App Icon macOS, Firebase Init Fix |
| Phase 8: Laporan & Export | ✅ Selesai | Tabel Anggaran bergaya dashboard + Export PDF |
| Phase 9: Push Notifications | ✅ Selesai | Reminder harian & awal bulan |
| Phase 10: Firestore Security Rules | ✅ Selesai | Kunci database berdasar `userId` |

---

*Update roadmap ini setiap kali menyelesaikan milestone.*
