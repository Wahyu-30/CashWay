# CashWay — Panduan Implementasi untuk AI

## Status proyek saat ini

CashWay adalah aplikasi pelacak keuangan pribadi multiplatform untuk macOS dan iOS. Implementasi yang sedang berjalan **bukan lagi SwiftData/offline-only**: aplikasi memakai Firebase Authentication (Google Sign-In) dan Cloud Firestore untuk autentikasi serta sinkronisasi data realtime.

| Aspek | Standar saat ini |
|---|---|
| Bahasa | Swift 6.3 / mode concurrency ketat Xcode 26 |
| UI | SwiftUI untuk iOS dan macOS |
| State UI | `@Observable` untuk view model, `ObservableObject` untuk layanan Firebase yang menjadi `EnvironmentObject` |
| Database | Cloud Firestore |
| Autentikasi | Firebase Auth + Google Sign-In |
| Target | iOS 26.5+, macOS 26.5+ |
| Mata uang/UI | IDR dan Bahasa Indonesia |
| Isolasi UI | `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` |

Jangan mengembalikan proyek ke SwiftData, CloudKit, atau offline-only tanpa instruksi eksplisit pengguna.

## Struktur proyek

```
CASHWAY/
├── AGENT.md
├── README.md
├── PRD.md
├── DESIGN.md
├── ROADMAP.md
└── CashWay/
    ├── CashWay.xcodeproj/
    └── CashWay/
        ├── App/           # Entry point dan navigasi
        ├── Models/        # DTO Firestore: Transaction, Category, Wallet, Budget, SavingsGoal
        ├── Services/      # Firebase, Auth, DataStore, notifikasi, PDF
        ├── Utilities/     # warna, format IDR, data default, animasi, smart advice
        ├── ViewModels/    # state dan logika layar
        └── Views/         # seluruh layar SwiftUI
```

## Arsitektur data

`DataStore` adalah sumber data utama UI dan harus digunakan melalui `@EnvironmentObject`. Ia memasang Firestore snapshot listener untuk koleksi berikut:

- `transactions`
- `categories`
- `wallets`
- `budgets`
- `savingsGoals`

Setiap dokumen milik pengguna wajib memiliki `userId`, dan setiap read/write harus dibatasi pada UID Firebase Auth yang sedang aktif. Jangan pernah melakukan query atau delete lintas akun. Logout harus menghentikan listener lalu mengosongkan state lokal.

### Model Firestore

- Semua model yang diserialisasi Firestore menggunakan `Codable`.
- Karena target memakai default `MainActor`, model DTO (`Wallet`, `Category`, `Transaction`, `Budget`, dan `SavingsGoal`) harus tetap `nonisolated`. Ini memungkinkan Firestore melakukan encode/decode di luar UI actor.
- Uang menggunakan `Decimal`, bukan `Double` atau `Float`.
- Gunakan `CurrencyFormatter` untuk menampilkan Rupiah.
- Transaksi menyimpan snapshot kategori dan wallet agar query Firestore sederhana dan data historis tetap dapat ditampilkan.

## Aturan concurrency

- `DataStore`, `NotificationManager`, `PDFExporter`, dan view model UI berjalan di `@MainActor`.
- Callback atau API async Firestore tidak boleh langsung memanggil API UI/MainActor dari konteks nonisolated. Gunakan fungsi `async`/`await` atau kembali ke `MainActor` secara eksplisit.
- Untuk helper Firestore, batas generic harus sempit: `Decodable` saat membaca dan `Encodable` saat menulis.
- Jangan menghapus `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` hanya untuk menyembunyikan warning. Perbaiki batas actor pada tipe atau callback yang benar.

## Pencegahan dan pembersihan duplikat

Data default (kategori dan wallet) memakai ID Firestore deterministik yang mencakup UID pengguna. Dengan demikian beberapa proses seeding untuk akun yang sama akan menulis dokumen yang sama, bukan membuat dokumen baru.

Tombol **Bersihkan Data Duplikat** di Settings memanggil `DataStore.cleanupDuplicates()`:

- hanya membaca dan mengubah dokumen dengan `userId` pengguna aktif;
- kategori dianggap sama hanya jika `name` **dan** `type` sama; kategori `Lainnya` income dan expense harus tetap terpisah;
- wallet dianggap sama jika `name` sama;
- tidak boleh menghapus dokumen pengguna lain atau dokumen lama tanpa `userId`;
- gunakan batch Firestore dan jangan mengirim write kosong.

Jangan membuat proses cleanup otomatis yang menghapus data tanpa aksi pengguna. Jangan mengubah struktur, rules, atau data Firestore yang sudah ada kecuali pengguna memberi izin jelas.

## Aturan UI dan fitur

- UI tetap SwiftUI lintas iOS/macOS; gunakan `#if os(iOS)` / `#if os(macOS)` bila diperlukan.
- Warna melalui `Color.cw…` dan sistem desain di `ColorExtensions.swift`.
- Dashboard, transaksi, tabungan, budget, laporan, smart advice, settings, Google login, notifikasi lokal, dan ekspor PDF sudah diimplementasikan.
- Smart Advice adalah rule-based, bukan layanan AI eksternal.
- Gunakan komponen dan animasi yang ada; pertahankan dark premium design saat menambah UI.
- Jangan menambah dependensi pihak ketiga tanpa persetujuan. Firebase dan Google Sign-In adalah dependensi yang sudah disetujui.

## Cara kerja aman

1. Baca file terkait dan cek perubahan kerja yang sudah ada sebelum mengedit.
2. Buat perubahan sekecil mungkin yang menyelesaikan masalah.
3. Jangan menggunakan `git reset`, `checkout --`, atau operasi database destruktif.
4. Build macOS dan, bila relevan, iOS setelah perubahan. Bedakan error compiler aplikasi dari warning lingkungan Xcode/Simulator.
5. Laporkan file yang diubah, hasil build, dan batasan yang belum dapat diverifikasi.

## Catatan dokumentasi

`README.md`, `PRD.md`, `DESIGN.md`, dan `ROADMAP.md` memuat sebagian informasi historis dari fase SwiftData/offline-first. Untuk keputusan implementasi yang berhubungan dengan kode saat ini, gunakan arsitektur Firebase yang dijelaskan dalam dokumen ini dan validasi terhadap source code aktual.
