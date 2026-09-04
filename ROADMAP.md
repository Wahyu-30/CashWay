# 🗺️ CashWay — Roadmap Pengembangan

**Versi Saat Ini:** 1.0 (Production)
**Tech Stack:** Swift 6.3 · SwiftUI · Firebase Firestore · Firebase Auth · Xcode 26
**Update Terakhir:** 1 September 2026

---

## 🔭 Visi Jangka Panjang

```
v1.0 → MVP (Firebase Cloud Sync, macOS + iOS) ✅ SELESAI
v1.1 → Fitur Lanjutan (Custom Category, Recurring Transactions, Widget)
v2.0 → Kolaborasi & Import CSV Rekening Koran + Advanced Analytics
```

---

## ✅ Phase 1 — Foundation & Setup
**Status: SELESAI**

- Project Xcode multi-platform (macOS + iOS target)
- Navigasi TabView / NavigationSplitView
- Color palette & design tokens (dark premium)
- SF Symbol icon library

---

## ✅ Phase 2 — Core CRUD Transaksi
**Status: SELESAI**

- Input transaksi (jumlah, tipe, kategori, wallet, tanggal, catatan)
- Riwayat transaksi grouped by date
- Edit transaksi (swipe kanan / sheet)
- **Hapus transaksi dengan konfirmasi alert**
  - iOS: swipe kiri
  - Mac: klik kanan → "Hapus Transaksi"
- Filter tipe (Semua / Pengeluaran / Pemasukan)
- Search transaksi by kata kunci
- **Filter bulan** di halaman Transaksi (default: bulan ini)
  - Navigasi < Bulan Ini > di atas daftar
  - Tombol "Semua Bulan" untuk lihat seluruh riwayat

---

## ✅ Phase 3 — Dashboard & Visualisasi
**Status: SELESAI**

- Greeting + tanggal hari ini
- **Kartu "Total Saldo" (kumulatif lintas bulan)**
  - Saldo otomatis terbawa dari bulan ke bulan — tidak perlu input ulang
  - Badge Masuk/Keluar menampilkan aktivitas bulan berjalan
- Sumber Pemasukan (Gaji, Freelance, Orang Tua, Lainnya)
- Bar chart Pemasukan vs Pengeluaran per hari
- Smart Advice engine (rule-based)
- Navigasi bulan `< Agustus 2026 >`
- **Banner sertifikat sideload** — hanya muncul saat ≤ 1 hari tersisa

---

## ✅ Phase 4 — Wallet & Budget
**Status: SELESAI**

### Wallet
- Multi-wallet: Tunai, Bank, GoPay, DANA
- Saldo per wallet (real-time dari transaksi)
- Add / Edit wallet
- **Transfer antar wallet** (Pindah dana antar rekening tanpa masuk Pemasukan/Pengeluaran)

### Budget
- Budget per kategori per bulan
- Progress bar (Aman / Hampir Habis / Melewati Budget)
- **Group Budget (Auto-Budget Wizard 50/30/20):**
  - "Kebutuhan Pokok (50%)" → 1 budget untuk Makan & Minum, Transportasi, Kesehatan, Rumah & Tagihan, Pendidikan
  - "Keinginan (30%)" → 1 budget untuk Hiburan, Belanja, Langganan Digital, Perjalanan, Perlengkapan Kerja
  - 20% Tabungan tidak dibuat sebagai budget (hanya informasi)
- **Hapus budget dengan konfirmasi**
  - Tombol 🗑 langsung di kartu budget (iOS)
  - Klik kanan → "Hapus" (Mac)
  - Laporan otomatis terupdate setelah hapus
- Analisis Historis (rata-rata 3 bulan terakhir)

---

## ✅ Phase 5 — Laporan & Export PDF
**Status: SELESAI**

- Laporan bulanan: ringkasan per kategori
- Tabel Daftar Pengeluaran per Kategori (responsif untuk iPhone)
- Chart tren bulanan
- Export PDF (PDFKit) — simpan ke Files app / share sheet
- Navigasi bulan di Laporan

---

## ✅ Phase 6 — Migrasi Firebase & Auth
**Status: SELESAI**

- Google Sign-In macOS & iOS via Firebase Auth
- Cloud Firestore realtime sync
- Isolasi data per akun (`userId` scoping di semua koleksi)
- Login / Logout multi-akun
- Firestore Security Rules (data hanya bisa dibaca/ditulis pemiliknya)

---

## ✅ Phase 7 — UI Polish & Bug Fixes
**Status: SELESAI**

- Animasi SlideInCard pada semua layar
- AnimatedNumberText untuk angka berubah halus
- App icon macOS & iOS
- Dark premium design konsisten
- Tabel Laporan responsif di iPhone (kolom lebih kecil, minimumScaleFactor)
- Empty states yang informatif

---

## ✅ Phase 8 — Notifikasi & Seeding
**Status: SELESAI**

- Notifikasi pengingat harian (jam bisa diatur)
- Notifikasi awal bulan (09:00)
- Seed kategori & wallet default otomatis saat pertama login
- Tombol "Bersihkan Data Duplikat" di Settings
- `seedIfNeeded` menggunakan async/await + Firestore check

---

## 🚧 Phase 9 — Kategori Custom (v1.1 — Belum Dimulai)

**Goal:** User bisa tambah kategori sendiri

- Tambah kategori baru (nama + icon SF Symbol + warna)
- Edit kategori existing
- Soft-delete kategori (tidak bisa hapus jika dipakai transaksi)
- Contoh use case: "Potong Rambut" → kategori "Perawatan Diri" baru

---

## 🚧 Backlog (v1.1+)

| Fitur | Estimasi | Catatan |
|-------|----------|---------|
| Kategori custom (tambah/edit) | 1 minggu | Phase 9 |
| iOS Widget (saldo + quick add) | 1 minggu | Butuh App Group entitlement |
| Recurring transactions (cicilan, langganan) | 1 minggu | |
| Import CSV rekening koran | 2 minggu | |
| Siri Shortcut "Tambah pengeluaran Rp X" | 1 minggu | |
| Face ID / Touch ID lock | 3 hari | |
| macOS Menu Bar widget | 1 minggu | |

---

## 📊 Progress Tracker

| Phase | Status | Update Terakhir |
|-------|--------|-----------------|
| Phase 1: Foundation & Setup | ✅ Selesai | Dark Mode, TabView, Design Tokens |
| Phase 2: CRUD Transaksi | ✅ Selesai | Filter bulan + swipe delete + Mac context menu |
| Phase 3: Dashboard | ✅ Selesai | Total Saldo kumulatif, banner sertifikat hari ke-6/7 |
| Phase 4: Wallet & Budget | ✅ Selesai | Group budget 50/30, hapus budget + konfirmasi |
| Phase 5: Laporan & PDF | ✅ Selesai | Tabel responsif iPhone, PDF export |
| Phase 6: Firebase & Auth | ✅ Selesai | Google Sign-In, Firestore realtime, Security Rules |
| Phase 7: UI Polish | ✅ Selesai | SlideInCard, AnimatedNumber, App Icon |
| Phase 8: Notifikasi & Seeding | ✅ Selesai | Seed async/await, cleanup duplikat, notifikasi |
| Phase 9: Kategori Custom | 🔲 Belum | v1.1 |

---

*Update roadmap ini setiap kali menyelesaikan milestone.*
