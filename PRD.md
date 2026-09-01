# 📋 Product Requirements Document (PRD)
# CashWay — Personal Finance Tracker

**Versi:** 1.0 (Production)
**Update Terakhir:** 1 September 2026
**Author:** Wahyu Ahmad Cahyadi
**Platform:** macOS 26 + iOS 26
**Backend:** Firebase Firestore + Firebase Auth (Google Sign-In)

---

## 1. Latar Belakang & Tujuan

### Problem Statement
Sebagai videografer dan editor freelance/kantoran, penghasilan bersifat variabel (project-based, gaji tetap + bonus, dll). Sulit memantau arus kas masuk dan keluar secara real-time tanpa tools yang tepat.

### Tujuan Produk
Membangun aplikasi keuangan pribadi yang memungkinkan pengguna:
1. Mencatat setiap transaksi keuangan dengan cepat (< 10 detik)
2. Melihat ringkasan keuangan secara visual dan jelas
3. Mengontrol pengeluaran melalui sistem budget
4. Mengakses data yang sama di MacBook dan iPhone secara real-time (Firebase Sync)

---

## 2. Target Pengguna

**Persona:** Wahyu — Videografer & Editor
- Usia: 25-35 tahun
- Profesi: Kreatif, bekerja di kantor + freelance
- Penghasilan: Campuran (gaji tetap + project)
- Perangkat: MacBook + iPhone
- Kebutuhan: Pantau pengeluaran harian, budget bulanan, laporan sederhana
- Data disimpan di Firebase Cloud (private per akun Google)

---

## 3. Ruang Lingkup (Scope)

### In Scope (Versi 1.0 — Sudah Selesai)
- ✅ CRUD transaksi (income & expense) dengan konfirmasi hapus
- ✅ Filter transaksi per bulan (navigasi < Bulan Tahun >)
- ✅ Kategori preset (14 expense + 6 income)
- ✅ Multi-wallet (Tunai, Bank, GoPay, OVO, dll)
- ✅ Dashboard dengan "Total Saldo" kumulatif (terbawa antar bulan)
- ✅ Chart Pemasukan vs Pengeluaran per hari
- ✅ Sumber Pemasukan (Gaji, Freelance, Orang Tua, Lainnya)
- ✅ Budget Group per bulan (Auto-Budget Wizard 50/30/20)
- ✅ Hapus budget dengan konfirmasi
- ✅ Smart Advice (rule-based, bukan AI eksternal)
- ✅ Laporan bulanan + export PDF
- ✅ Notifikasi pengingat lokal (harian & awal bulan)
- ✅ Dark mode (default)
- ✅ Cloud sync realtime (Firebase Firestore)
- ✅ Isolasi data per akun Google (userId scoping)
- ✅ Login/Logout Google Sign-In (macOS & iOS)

### Out of Scope (Versi 1.0)
- ❌ Kategori custom (tambah/edit kategori sendiri) → v1.1
- ❌ Import otomatis dari rekening bank (API banking)
- ❌ Investasi / portfolio tracker
- ❌ Multi-currency
- ❌ Sharing/collaboration dengan orang lain
- ❌ App Store distribution
- ❌ iOS Widget

---

## 4. User Stories

### 4.1 Transaksi

| ID | Story | Status |
|----|-------|--------|
| T-01 | Tambah transaksi pengeluaran (kategori, jumlah, tanggal, catatan) | ✅ Done |
| T-02 | Tambah transaksi pemasukan (sumber: gaji, freelance, orang tua, dll) | ✅ Done |
| T-03 | Edit transaksi yang sudah dicatat | ✅ Done |
| T-04 | Hapus transaksi dengan konfirmasi (iOS swipe kiri / Mac klik kanan) | ✅ Done |
| T-05 | Filter transaksi per bulan (default bulan ini, bisa navigasi ke bulan lain) | ✅ Done |
| T-06 | Lihat semua riwayat transaksi (tombol "Semua Bulan") | ✅ Done |
| T-07 | Cari transaksi berdasarkan kata kunci atau filter tipe | ✅ Done |

### 4.2 Dashboard

| ID | Story | Status |
|----|-------|--------|
| D-01 | Lihat "Total Saldo" yang akumulatif dari semua bulan s.d. bulan ini | ✅ Done |
| D-02 | Lihat total pemasukan dan pengeluaran bulan ini (badge Masuk/Keluar) | ✅ Done |
| D-03 | Lihat grafik bar pemasukan vs pengeluaran per hari | ✅ Done |
| D-04 | Lihat sumber pemasukan (Gaji, Freelance, Orang Tua) | ✅ Done |
| D-05 | Lihat 5 transaksi terakhir di dashboard | ✅ Done |
| D-06 | Navigasi bulan (< Agustus 2026 >) | ✅ Done |
| D-07 | Saldo bulan sebelumnya otomatis terbawa ke bulan baru (tanpa input ulang) | ✅ Done |

### 4.3 Budget

| ID | Story | Status |
|----|-------|--------|
| B-01 | Set budget group "Kebutuhan Pokok" (50%) untuk banyak kategori sekaligus | ✅ Done |
| B-02 | Set budget group "Keinginan" (30%) untuk banyak kategori sekaligus | ✅ Done |
| B-03 | Lihat progress pemakaian budget (progress bar + %) | ✅ Done |
| B-04 | Warning visual saat budget hampir habis (>80%) atau terlampaui (>100%) | ✅ Done |
| B-05 | Hapus budget dengan konfirmasi (tombol 🗑 di kartu / Mac klik kanan) | ✅ Done |
| B-06 | Laporan terupdate otomatis setelah budget dihapus | ✅ Done |
| B-07 | Auto-Budget Wizard: buat budget otomatis dari pemasukan bulan ini | ✅ Done |

### 4.4 Wallet

| ID | Story | Status |
|----|-------|--------|
| W-01 | Multi-wallet (Tunai, Bank, GoPay, OVO, dll) | ✅ Done |
| W-02 | Lihat saldo masing-masing wallet (real-time dari transaksi) | ✅ Done |
| W-03 | Add / Edit wallet | ✅ Done |

### 4.5 Laporan

| ID | Story | Status |
|----|-------|--------|
| R-01 | Laporan ringkasan per bulan (pemasukan, pengeluaran, saldo, per kategori) | ✅ Done |
| R-02 | Tabel Daftar Pengeluaran per Kategori (responsif di iPhone) | ✅ Done |
| R-03 | Export laporan bulanan ke PDF | ✅ Done |

### 4.6 Akun & Sync

| ID | Story | Status |
|----|-------|--------|
| S-01 | Login dengan akun Google (Google Sign-In) | ✅ Done |
| S-02 | Data tersinkronisasi realtime antara MacBook dan iPhone | ✅ Done |
| S-03 | Data terisolasi per akun Google (tidak ada data bocor antar user) | ✅ Done |
| S-04 | Logout dengan aman (hapus data lokal, hentikan listener) | ✅ Done |

---

## 5. Model Data

### Transaction
```
- id: String (UUID)
- userId: String          // UID Firebase Auth
- amount: Decimal
- type: TransactionType   // .income / .expense / .transfer
- category: Category?     // snapshot kategori
- wallet: Wallet?         // snapshot wallet
- date: Date
- note: String?
- incomeTag: IncomeTag?   // .salary / .business / .parents / .other
```

### Category
```
- id: String
- userId: String
- name: String
- icon: String            // SF Symbol name
- colorHex: String
- type: CategoryType      // .income / .expense
```

### Wallet
```
- id: String
- userId: String
- name: String            // "BCA", "GoPay", "Tunai"
- icon: String
- colorHex: String
- initialBalance: Decimal
```

### Budget (dengan Group Budget Support)
```
- id: String
- userId: String
- amount: Decimal          // batas budget total untuk group ini
- month: Int
- year: Int
- category: Category?      // kategori utama (untuk icon & warna)
- groupName: String?       // "Kebutuhan Pokok (50%)" — jika nil, budget per-kategori biasa
- extraCategoryIds: [String] // ID kategori tambahan dalam group
- spent: Decimal           // virtual, dihitung dari semua transaksi dalam allCategoryIds
```

### SavingsGoal
```
- id: String
- userId: String
- name: String
- targetAmount: Decimal
- currentAmount: Decimal
- deadline: Date?
- icon: String
- colorHex: String
```

---

## 6. Format Angka
- Semua jumlah dalam **IDR (Rupiah)**
- Format tampilan: `Rp 1.250.000` (titik sebagai pemisah ribuan)
- Input: angka mentah, auto-format saat tampil via `CurrencyFormatter`

---

## 7. Kategori Default (Preset)

**Pengeluaran (14):**
Makan & Minum, Transportasi, Belanja, Kesehatan, Hiburan, Langganan Digital,
Rumah & Tagihan, Pendidikan, Perlengkapan Kerja, Equipment, Software & Tools,
Perjalanan, Hadiah, Lainnya

**Pemasukan (6):**
Gaji Kantor, Freelance/Project, Orang Tua, Investasi, Bonus/Hadiah, Lainnya

---

## 8. Persyaratan Non-Fungsional

| Aspek | Persyaratan |
|-------|-------------|
| **Performance** | Load dashboard < 1 detik; transaksi tersimpan < 1 detik |
| **Sync** | Realtime sync via Firebase Firestore |
| **Security** | Data terisolasi per userId; Firestore Security Rules |
| **Offline** | App masih bisa dibaca saat offline (Firestore cache), write saat online |
| **Accessibility** | Support VoiceOver, Dynamic Type |
| **Localization** | Bahasa Indonesia |

---

## 9. Design Requirements

### Visual Identity
- **Nama:** CashWay
- **Tagline:** "Arus kasmu, kendalimu."
- **Tone:** Professional, Clean, Dark-first

### Color Palette
| Token | Hex | Penggunaan |
|-------|-----|------------|
| `cwBackground` | `#0F0F14` | Background utama |
| `cwSurface` | `#1A1A2E` | Card, Sheet |
| `cwAccent` | `#00C9A7` | Primary action, active state |
| `cwIncome` | `#4CAF82` | Angka pemasukan |
| `cwExpense` | `#FF6B6B` | Angka pengeluaran |
| `cwWarning` | `#F4A261` | Budget hampir habis |
| `cwTextPrimary` | `#FFFFFF` | Teks utama |
| `cwTextSecondary` | `#8B8FA8` | Label, subtitle |
| `cwBorder` | `#2A2A3E` | Border card |

---

## 10. Risiko & Mitigasi

| Risiko | Dampak | Mitigasi |
|--------|--------|----------|
| Firebase outage | Sedang | Firestore offline cache masih berfungsi |
| Sertifikat sideload kedaluarsa (7 hari) | Tinggi | Banner peringatan hari ke-6/7; rebuild dari Xcode |
| Duplikat data saat install ulang | Sedang | ID deterministik per-user + tombol cleanup |
| Data terhapus tidak sengaja | Tinggi | Konfirmasi alert sebelum setiap penghapusan |

---

*Dokumen ini akan diperbarui seiring perkembangan project.*
