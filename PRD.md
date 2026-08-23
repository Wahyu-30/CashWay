# 📋 Product Requirements Document (PRD)
# CashWay — Personal Finance Tracker

**Versi:** 1.0  
**Tanggal:** Agustus 2026  
**Author:** Wahyu Ahmad Cahyadi  
**Platform:** macOS 26 + iOS 26  

---

## 1. Latar Belakang & Tujuan

### Problem Statement
Sebagai videografer dan editor freelance/kantoran, penghasilan bersifat variabel (project-based, gaji tetap + bonus, dll). Sulit memantau arus kas masuk dan keluar secara real-time tanpa tools yang tepat. Aplikasi keuangan yang ada di pasaran:
- Memerlukan langganan berbayar
- Menyimpan data di cloud pihak ketiga
- Tidak bisa offline sepenuhnya
- Terlalu kompleks / tidak intuitif

### Tujuan Produk
Membangun aplikasi **offline-first** yang memungkinkan pengguna:
1. Mencatat setiap transaksi keuangan dengan cepat (< 10 detik)
2. Melihat ringkasan keuangan secara visual dan jelas
3. Mengontrol pengeluaran melalui sistem budget
4. Mengakses data yang sama di MacBook dan iPhone

---

## 2. Target Pengguna

**Persona:** Wahyu — Videografer & Editor  
- Usia: 25-35 tahun
- Profesi: Kreatif, bekerja di kantor + freelance
- Penghasilan: Campuran (gaji tetap + project)
- Perangkat: MacBook + iPhone 13
- Kebutuhan: Pantau pengeluaran harian, budget bulanan, laporan sederhana
- Pain point: Tidak ingin data keuangan tersimpan di cloud orang lain

---

## 3. Ruang Lingkup (Scope)

### In Scope (Versi 1.0)
- ✅ CRUD transaksi (income & expense)
- ✅ Kategori preset + custom
- ✅ Multi-wallet (Tunai, Bank, GoPay, OVO, dll)
- ✅ Dashboard dengan chart bulanan
- ✅ Budget per kategori per bulan
- ✅ Notifikasi budget (in-app)
- ✅ Filter & pencarian riwayat transaksi
- ✅ Export PDF laporan bulanan
- ✅ Dark mode (default)
- ✅ iCloud sync antar perangkat (opsional, via toggle)

### Out of Scope (Versi 1.0)
- ❌ Import otomatis dari rekening bank (API banking)
- ❌ Investasi / portfolio tracker
- ❌ Multi-currency
- ❌ Sharing/collaboration dengan orang lain
- ❌ App Store distribution

---

## 4. User Stories

### 4.1 Transaksi

| ID | Story | Priority |
|----|-------|----------|
| T-01 | Sebagai user, saya ingin menambah transaksi pengeluaran dengan memilih kategori, memasukkan jumlah (Rupiah), tanggal, dan catatan | 🔴 High |
| T-02 | Sebagai user, saya ingin menambah transaksi pemasukan dengan sumber (gaji, freelance, dll) | 🔴 High |
| T-03 | Sebagai user, saya ingin mengedit transaksi yang sudah dicatat | 🔴 High |
| T-04 | Sebagai user, saya ingin menghapus transaksi dengan konfirmasi | 🔴 High |
| T-05 | Sebagai user, saya ingin mencari transaksi berdasarkan kata kunci atau filter kategori/tanggal | 🟡 Medium |
| T-06 | Sebagai user, saya ingin melihat detail transaksi lengkap | 🟡 Medium |

### 4.2 Dashboard

| ID | Story | Priority |
|----|-------|----------|
| D-01 | Sebagai user, saya ingin melihat saldo total semua wallet di dashboard | 🔴 High |
| D-02 | Sebagai user, saya ingin melihat total pemasukan dan pengeluaran bulan ini | 🔴 High |
| D-03 | Sebagai user, saya ingin melihat grafik batang pengeluaran per hari dalam sebulan | 🟡 Medium |
| D-04 | Sebagai user, saya ingin melihat pie chart distribusi pengeluaran per kategori | 🟡 Medium |
| D-05 | Sebagai user, saya ingin melihat 5 transaksi terakhir di dashboard | 🟡 Medium |

### 4.3 Budget

| ID | Story | Priority |
|----|-------|----------|
| B-01 | Sebagai user, saya ingin menetapkan budget maksimal per kategori per bulan | 🔴 High |
| B-02 | Sebagai user, saya ingin melihat progress penggunaan budget (progress bar) | 🔴 High |
| B-03 | Sebagai user, saya ingin mendapat notifikasi ketika pengeluaran mencapai 80% dari budget | 🟡 Medium |
| B-04 | Sebagai user, saya ingin budget otomatis ter-reset tiap awal bulan | 🟡 Medium |

### 4.4 Wallet / Akun

| ID | Story | Priority |
|----|-------|----------|
| W-01 | Sebagai user, saya ingin membuat beberapa wallet (Tunai, BCA, GoPay, OVO, dll) | 🔴 High |
| W-02 | Sebagai user, saya ingin melihat saldo masing-masing wallet | 🔴 High |
| W-03 | Sebagai user, saya ingin mencatat transfer antar wallet | 🟡 Medium |

### 4.5 Laporan

| ID | Story | Priority |
|----|-------|----------|
| R-01 | Sebagai user, saya ingin melihat ringkasan laporan per bulan | 🟡 Medium |
| R-02 | Sebagai user, saya ingin export laporan bulanan ke PDF | 🟡 Medium |

### 4.6 Sinkronisasi

| ID | Story | Priority |
|----|-------|----------|
| S-01 | Sebagai user, saya ingin data saya otomatis tersinkronisasi antara MacBook dan iPhone via iCloud | 🟢 Low |
| S-02 | Sebagai user, saya ingin bisa menonaktifkan iCloud sync | 🟢 Low |

---

## 5. Persyaratan Fungsional Detail

### 5.1 Model Data

#### Transaction
```
- id: UUID
- amount: Decimal          // dalam Rupiah, selalu positif
- type: TransactionType    // .income / .expense / .transfer
- category: Category
- wallet: Wallet
- date: Date
- note: String?
- createdAt: Date
- updatedAt: Date
```

#### Category
```
- id: UUID
- name: String             // "Makan", "Transport", "Gaji", dll
- icon: String             // SF Symbol name
- color: String            // Hex color
- type: CategoryType       // .income / .expense / .both
- isDefault: Bool
```

#### Wallet
```
- id: UUID
- name: String             // "BCA", "GoPay", "Tunai"
- type: WalletType         // .cash / .bank / .ewallet / .creditCard
- icon: String
- color: String
- initialBalance: Decimal
- currentBalance: Decimal  // computed dari transactions
```

#### Budget
```
- id: UUID
- category: Category
- amount: Decimal          // batas budget
- month: Int
- year: Int
- spent: Decimal           // computed dari transactions
```

### 5.2 Format Angka
- Semua jumlah dalam **IDR (Rupiah)**
- Format tampilan: `Rp 1.250.000` (titik sebagai pemisah ribuan)
- Input: angka mentah, auto-format saat tampil

### 5.3 Kategori Default (Preset)

**Pengeluaran:**
- 🍽️ Makan & Minum
- 🚗 Transportasi
- 🛒 Belanja
- 💊 Kesehatan
- 🎮 Hiburan
- 📱 Langganan Digital
- 🏠 Rumah & Tagihan
- 📚 Pendidikan
- 💼 Perlengkapan Kerja
- 🎬 Equipment (kamera, drone, dll)
- 💻 Software & Tools
- ✈️ Perjalanan
- 🎁 Hadiah
- 🌀 Lainnya

**Pemasukan:**
- 💰 Gaji
- 🎯 Freelance / Project
- 📈 Investasi
- 🎁 Hadiah / Bonus
- 💸 Transfer Masuk
- 🌀 Lainnya

---

## 6. Persyaratan Non-Fungsional

| Aspek | Persyaratan |
|-------|-------------|
| **Performance** | Aplikasi terbuka < 2 detik; transaksi tersimpan < 1 detik |
| **Storage** | Maksimal 50MB untuk 10.000 transaksi |
| **Offline** | 100% berfungsi tanpa koneksi internet |
| **Security** | Data terenkripsi di level sistem (iOS Data Protection, macOS FileVault) |
| **Accessibility** | Support VoiceOver, Dynamic Type |
| **Localization** | Bahasa Indonesia (default), Bahasa Inggris |

---

## 7. Design Requirements

### Visual Identity
- **Nama:** CashWay
- **Tagline:** "Arus kasmu, kendalimu."
- **Tone:** Professional, Clean, Dark-first

### Color Palette
| Token | Hex | Penggunaan |
|-------|-----|------------|
| `background` | `#0F0F14` | Background utama |
| `surface` | `#1A1A2E` | Card, Sheet |
| `surface-elevated` | `#242438` | Elevated card |
| `accent` | `#00C9A7` | Primary action, active state |
| `income` | `#4CAF82` | Angka pemasukan |
| `expense` | `#FF6B6B` | Angka pengeluaran |
| `text-primary` | `#FFFFFF` | Teks utama |
| `text-secondary` | `#8B8FA8` | Label, subtitle |
| `border` | `#2A2A3E` | Border card |

### Typography (SF Pro)
- **Heading XL:** SF Pro Display Bold, 34pt
- **Heading L:** SF Pro Display Bold, 28pt
- **Heading M:** SF Pro Display Semibold, 22pt
- **Body:** SF Pro Text Regular, 16pt
- **Caption:** SF Pro Text Regular, 13pt
- **Amount:** SF Pro Rounded Bold (untuk angka uang)

---

## 8. Success Metrics (KPI)

| Metrik | Target |
|--------|--------|
| Input transaksi | < 10 detik per entri |
| Crash rate | 0% (personal app) |
| Waktu load dashboard | < 1 detik |
| Akurasi data | 100% offline reliability |

---

## 9. Risiko & Mitigasi

| Risiko | Dampak | Mitigasi |
|--------|--------|----------|
| Kehilangan data | Tinggi | iCloud backup + manual export JSON |
| iPhone storage penuh (2.79 GB tersisa) | Sedang | Optimize SwiftData storage, max ~50MB |
| Xcode update breaking changes | Rendah | Lock ke Xcode 26.6 selama development |

---

*Dokumen ini akan diperbarui seiring perkembangan project.*
