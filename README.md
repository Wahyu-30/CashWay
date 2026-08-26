# 💸 CashWay

> Aplikasi pemantau keuangan pribadi yang berjalan offline di MacBook & iPhone kamu.

![Platform](https://img.shields.io/badge/Platform-macOS%2026%20%7C%20iOS%2026-black?style=flat-square&logo=apple)
![Swift](https://img.shields.io/badge/Swift-6.3-orange?style=flat-square&logo=swift)
![Xcode](https://img.shields.io/badge/Xcode-26.6-blue?style=flat-square)
![License](https://img.shields.io/badge/License-Personal-green?style=flat-square)

---

## ✨ Tentang CashWay

**CashWay** adalah aplikasi keuangan pribadi yang dirancang untuk individu yang ingin memantau arus kas mereka secara mandiri, tanpa langganan, tanpa cloud pihak ketiga, dan tanpa internet. Semua data tersimpan aman di perangkatmu sendiri.

Dibuat dengan **SwiftUI + SwiftData** — teknologi terbaru Apple yang memungkinkan satu codebase berjalan mulus di MacBook dan iPhone secara bersamaan.

---

## 📱 Fitur Utama

| Fitur | Deskripsi |
|-------|-----------|
| 💰 Catat Transaksi | Input pemasukan & pengeluaran dengan cepat |
| 🏷️ Kategori | Preset + custom kategori sesuai kebutuhan |
| 📊 Dashboard | Grafik & ringkasan keuangan bulanan |
| 🎯 Budget | Set anggaran per kategori, dapat notifikasi jika mendekati limit |
| 🔍 Riwayat | Filter, search, dan lihat semua transaksi |
| 📄 Laporan | Export ringkasan bulanan ke PDF |
| 🔄 Multi-Wallet | Kelola Tunai, Bank, GoPay, OVO dalam satu tempat |
| ☁️ iCloud Sync | Sinkronisasi antar MacBook ↔ iPhone (opsional) |

---

## ⚙️ Persyaratan Sistem

| | Minimum |
|---|---|
| **MacBook** | macOS 26 (Tahoe) |
| **iPhone** | iOS 26, iPhone 13 ke atas |
| **Xcode** | 26.6 |
| **Swift** | 6.3.3 |
| **Apple ID** | Diperlukan untuk install ke device |

---

## 🚀 Cara Instalasi

### 1. Clone / Download Project
```bash
# Jika menggunakan Git
git clone https://github.com/Wahyu-30/CashWay.git

# Atau download ZIP dan extract ke folder yang diinginkan
```

### 2. Setup Firebase (Penting)
Karena aplikasi ini menggunakan Firebase untuk autentikasi dan database, file konfigurasi Firebase dirahasiakan dan tidak di-push ke GitHub. Kamu perlu menambahkannya secara manual:
1. Buat project baru di [Firebase Console](https://console.firebase.google.com/).
2. Tambahkan aplikasi iOS/macOS dengan Bundle ID `com.namakamu.cashway`.
3. Aktifkan **Authentication** (Google Sign-In) & **Firestore Database**.
4. Download file `GoogleService-Info.plist`.
5. Masukkan file tersebut ke dalam folder `CashWay/CashWay/App/` di Xcode project kamu.

### 3. Buka di Xcode
```bash
open CashWay.xcodeproj
```
Atau buka Xcode → File → Open → pilih file `CashWay.xcodeproj`

### 3. Setting Bundle ID & Team
1. Pilih project `CashWay` di sidebar Xcode
2. Klik tab **Signing & Capabilities**
3. Ubah **Bundle Identifier** menjadi: `com.namakamu.cashway`
4. Di **Team**, pilih Apple ID kamu (login jika belum)

### 4. Install ke iPhone
1. Sambungkan iPhone ke Mac via USB
2. Pilih device iPhone kamu di toolbar Xcode
3. Tekan tombol ▶ **Run** atau `Cmd + R`
4. Di iPhone, buka **Settings → General → VPN & Device Management**
5. Trust developer certificate kamu
6. Selesai! CashWay siap digunakan 🎉

### 5. Run di MacBook
1. Di toolbar Xcode, pilih **My Mac** sebagai target
2. Tekan `Cmd + R`
3. Aplikasi akan terbuka langsung di Mac

---

## 📁 Struktur Project

```
CashWay/
├── CashWay.xcodeproj/
├── Shared/                         # Kode bersama macOS + iOS
│   ├── App/
│   │   └── CashWayApp.swift        # Entry point aplikasi
│   ├── Models/                     # Data models (SwiftData)
│   │   ├── Transaction.swift
│   │   ├── Category.swift
│   │   ├── Budget.swift
│   │   └── Wallet.swift
│   ├── ViewModels/                 # Business logic
│   │   ├── DashboardViewModel.swift
│   │   ├── TransactionViewModel.swift
│   │   └── BudgetViewModel.swift
│   ├── Views/                      # UI screens
│   │   ├── Dashboard/
│   │   ├── Transactions/
│   │   ├── Budget/
│   │   ├── Reports/
│   │   └── Settings/
│   ├── Components/                 # Komponen UI reusable
│   └── Utilities/                  # Helper & extensions
├── CashWay iOS/                    # iOS-specific files
├── CashWay macOS/                  # macOS-specific files
└── docs/                           # Dokumentasi
    ├── PRD.md
    ├── ROADMAP.md
    └── AGENT.md
```

---

## 📈 Status Pengerjaan (Progress)

Saat ini CashWay telah menyelesaikan implementasi fitur inti beserta cloud sync menggunakan **Firebase** dan autentikasi dengan **Google Sign-In**.

✅ **Selesai:**
- Setup Xcode Project (SwiftUI)
- UI/UX Premium Dark Mode
- Fitur input & hapus transaksi, Budget, Tabungan, & Laporan
- *Smart Advice Engine* (Peringatan cerdas pengeluaran & Auto-Budgeting)
- Migrasi Data Layer: Dari `SwiftData` (offline) menjadi **Firebase Firestore** (Realtime Cloud Sync)
- Autentikasi Pengguna: **Google Sign-In** untuk macOS dan iOS via Firebase Auth
- App Sandbox & Keychain Sharing di macOS
- Smooth UI Animations (`SlideInCard`) di semua halaman utama

⏳ **Akan Datang (Belum Selesai):**
1. **Push Notifications (Reminders):** Fitur pengingat mencatat pemasukan (tanggal 1 awal bulan) dan pengingat mencatat pengeluaran harian (malam hari).
2. **Data Privacy (Firestore Security Rules):** Mengubah rules database agar user hanya bisa melihat & mengedit datanya sendiri berdasarkan `userId`.
3. **Data Scoping:** Memasukkan `userId` ke dalam model data (Transaction, Budget, SavingsGoal) agar sinkronisasi benar-benar terpisah per pengguna.
4. **App Icon:** Menetapkan dan mengubah icon final aplikasi di Xcode.
5. **Export PDF:** Untuk pelaporan.

---

## 🎨 Design System

- **Tema default**: Dark Mode (Copilot Money Style)
- **Background**: `#000814` (Midnight Canvas)
- **Accent**: `#1c6cff` (Signal Blue)
- **Income**: `#4CAF82` (Emerald Green)
- **Expense**: `#FF6B6B` (Coral Red)
- **Typography**: SF Pro (system font Apple)

---

## 📝 Lisensi

Project ini untuk penggunaan pribadi. Tidak untuk didistribusikan secara komersial.

---

*Dibuat dengan ❤️ untuk Way — Tetap kontrol keuanganmu!*
