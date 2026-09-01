# 💸 CashWay

> Aplikasi pemantau keuangan pribadi realtime di MacBook & iPhone kamu.

![Platform](https://img.shields.io/badge/Platform-macOS%2026%20%7C%20iOS%2026-black?style=flat-square&logo=apple)
![Swift](https://img.shields.io/badge/Swift-6.3-orange?style=flat-square&logo=swift)
![Firebase](https://img.shields.io/badge/Backend-Firebase%20Firestore-yellow?style=flat-square&logo=firebase)
![Xcode](https://img.shields.io/badge/Xcode-26-blue?style=flat-square)
![License](https://img.shields.io/badge/License-Personal-green?style=flat-square)

---

## ✨ Tentang CashWay

**CashWay** adalah aplikasi keuangan pribadi yang dirancang untuk individu yang ingin memantau arus kas mereka secara mandiri. Data tersimpan aman di Firebase Cloud milik kamu sendiri dan tersinkronisasi realtime antara MacBook dan iPhone.

Dibuat dengan **SwiftUI + Firebase Firestore** — satu codebase berjalan mulus di MacBook dan iPhone secara bersamaan, dengan Google Sign-In sebagai autentikasi.

---

## 📱 Fitur Utama

| Fitur | Deskripsi |
|-------|-----------|
| 💰 Catat Transaksi | Input pemasukan & pengeluaran dengan cepat (< 10 detik) |
| 📅 Filter Bulan | Lihat transaksi per bulan; navigasi < Agustus 2026 > |
| 📊 Dashboard | Total Saldo kumulatif (terbawa antar bulan otomatis) |
| 🎯 Budget Group | Auto-Budget 50/30/20: "Kebutuhan Pokok" & "Keinginan" dalam 1 budget |
| 🔍 Riwayat | Filter, search, dan lihat riwayat transaksi per bulan |
| 📄 Laporan | Ringkasan per kategori + Export PDF |
| 🔄 Multi-Wallet | Kelola Tunai, Bank, GoPay, OVO dalam satu tempat |
| ☁️ Cloud Sync | Realtime sync via Firebase Firestore (MacBook ↔ iPhone) |
| 🔔 Notifikasi | Pengingat harian & awal bulan (jam bisa diatur) |
| 🧠 Smart Advice | Saran keuangan otomatis berbasis aturan |

---

## ⚙️ Persyaratan Sistem

| | Minimum |
|---|---|
| **MacBook** | macOS 26 (Tahoe) |
| **iPhone** | iOS 26 |
| **Xcode** | 26 |
| **Swift** | 6.3 |
| **Internet** | Diperlukan untuk Firebase sync |
| **Apple ID** | Diperlukan untuk install ke device (sideload) |

---

## 🚀 Cara Instalasi

### 1. Clone Project
```bash
git clone https://github.com/Wahyu-30/CashWay.git
```

### 2. Setup Firebase
File `GoogleService-Info.plist` tidak di-push ke GitHub. Tambahkan secara manual:
1. Buat project di [Firebase Console](https://console.firebase.google.com/).
2. Tambahkan aplikasi iOS/macOS dengan Bundle ID kamu.
3. Aktifkan **Authentication** (Google Sign-In) & **Firestore Database**.
4. Download `GoogleService-Info.plist` dan masukkan ke `CashWay/CashWay/App/`.

### 3. Buka di Xcode
```bash
open CashWay/CashWay.xcodeproj
```

### 4. Setting Signing
1. Pilih project `CashWay` di sidebar Xcode
2. Tab **Signing & Capabilities** → pilih **Team** (Apple ID kamu)

### 5. Install ke iPhone
1. Sambungkan iPhone ke Mac via USB
2. Pilih device iPhone di toolbar Xcode
3. Tekan `Cmd + R`
4. Di iPhone: **Settings → General → VPN & Device Management** → Trust developer
5. Selesai! 🎉

> ⚠️ **Catatan sertifikat:** Sideload gratis berlaku 7 hari. Aplikasi menampilkan peringatan di hari ke-6/7. Rebuild dari Xcode untuk memperbarui sertifikat.

### 6. Run di MacBook
Di toolbar Xcode pilih **My Mac** → tekan `Cmd + R`

---

## 📁 Struktur Project

```
CashWay/
├── AGENT.md          # Panduan implementasi untuk AI
├── PRD.md            # Product Requirements Document
├── ROADMAP.md        # Roadmap pengembangan
├── DESIGN.md         # Design system
└── CashWay/
    └── CashWay/
        ├── App/              # Entry point (CashWayApp.swift)
        ├── Models/           # DTO Firestore: Transaction, Category, Wallet, Budget, SavingsGoal
        ├── Services/         # DataStore, AuthService, NotificationManager, PDFExporter
        ├── Utilities/        # ColorExtensions, CurrencyFormatter, DefaultData, SmartAdvice
        ├── ViewModels/       # DashboardViewModel, TransactionViewModel, dll
        └── Views/
            ├── Auth/         # Login screen
            ├── Dashboard/    # Halaman utama
            ├── Transactions/ # Daftar & input transaksi
            ├── Savings/      # Tabungan & goals
            ├── Budget/       # Budget group & wizard
            ├── Reports/      # Laporan & PDF export
            └── Settings/     # Pengaturan, notifikasi, cleanup
```

---

## 📈 Status Pengerjaan

### ✅ Selesai (v1.0)

**Transaksi:**
- Input, edit, hapus transaksi (dengan konfirmasi)
- Filter per bulan (navigasi < Bulan Tahun >)
- "Semua Bulan" untuk lihat seluruh riwayat
- iOS: swipe kiri → hapus; swipe kanan → edit
- Mac: klik kanan → menu hapus/edit

**Dashboard:**
- **Total Saldo kumulatif** — saldo bulan lalu otomatis terbawa ke bulan ini
- Badge Masuk/Keluar menampilkan aktivitas bulan berjalan
- Chart Pemasukan vs Pengeluaran per hari
- Sumber pemasukan (Gaji, Freelance, Orang Tua)
- Banner peringatan sertifikat (hanya hari ke-6/7)

**Budget:**
- **Auto-Budget Wizard 50/30/20** → 2 budget group:
  - "Kebutuhan Pokok (50%)" = Makan & Minum + Transportasi + Kesehatan + Rumah & Tagihan + Pendidikan
  - "Keinginan (30%)" = Hiburan + Belanja + Langganan Digital + Perjalanan + Perlengkapan Kerja
  - 20% Tabungan → hanya info, tidak dibuat budget
- Hapus budget dengan konfirmasi (tombol 🗑 di kartu / Mac klik kanan)
- Laporan terupdate otomatis setelah hapus

**Laporan:**
- Tabel per kategori responsif (works di iPhone kecil)
- Export PDF berkualitas tinggi

**Infrastruktur:**
- Firebase Firestore realtime sync
- Google Sign-In (macOS & iOS)
- Isolasi data per akun (`userId`)
- Firestore Security Rules
- Seed data default (async/await, ID deterministik)
- Cleanup data duplikat di Settings
- Notifikasi lokal harian & awal bulan

### ⏳ Rencana (v1.1)
- Kategori custom (tambah/edit sendiri)
- iOS Widget (saldo + quick add)
- Recurring transactions (cicilan, langganan)

---

## 🎨 Design System

- **Tema:** Dark Mode (dark premium)
- **Background:** `#0F0F14`
- **Accent:** `#00C9A7` (Teal)
- **Income:** `#4CAF82` (Emerald Green)
- **Expense:** `#FF6B6B` (Coral Red)
- **Typography:** SF Pro (system font Apple)

---

## 📝 Lisensi

Project ini untuk penggunaan pribadi. Tidak untuk didistribusikan secara komersial.

---

*Dibuat dengan ❤️ untuk Way — Tetap kontrol keuanganmu!*
