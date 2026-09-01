# CashWay — Panduan Implementasi untuk AI

**Update terakhir:** 1 September 2026

---

## Status Proyek Saat Ini

CashWay adalah aplikasi pelacak keuangan pribadi multiplatform untuk macOS dan iOS. Implementasi yang sedang berjalan **bukan SwiftData/offline-only**: aplikasi memakai Firebase Authentication (Google Sign-In) dan Cloud Firestore untuk autentikasi serta sinkronisasi data realtime.

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

---

## Struktur Proyek

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
        ├── App/           # Entry point: CashWayApp.swift (seedIfNeeded async/await)
        ├── Models/        # DTO Firestore: Transaction, Category, Wallet, Budget, SavingsGoal
        ├── Services/      # DataStore, AuthService, NotificationManager, PDFExporter
        ├── Utilities/     # ColorExtensions, CurrencyFormatter, DefaultData, SlideInCard, SmartAdvice
        ├── ViewModels/    # DashboardViewModel, TransactionViewModel, dll
        └── Views/         # Semua layar SwiftUI
```

---

## Arsitektur Data

`DataStore` (`@MainActor ObservableObject`) adalah sumber data utama UI. Ia memasang Firestore snapshot listener untuk koleksi:

- `transactions`
- `categories`
- `wallets`
- `budgets`
- `savingsGoals`

Setiap dokumen wajib memiliki field `userId`. Setiap read/write dibatasi pada UID Firebase Auth aktif. Logout harus memanggil `clearData()` untuk hentikan listener dan kosongkan state lokal.

---

## Model Firestore

- Semua model menggunakan `Codable` + `nonisolated struct`.
- Uang menggunakan `Decimal`, bukan `Double` atau `Float`.
- Gunakan `CurrencyFormatter` untuk menampilkan Rupiah.

### Budget — Mendukung Group Budget

```swift
nonisolated struct Budget: Identifiable, Codable, Equatable, Hashable {
    var id: String
    var userId: String
    var amount: Decimal
    var month: Int
    var year: Int
    var category: Category?          // Kategori utama (icon & warna untuk display)
    var groupName: String?           // Nama group, mis: "Kebutuhan Pokok (50%)"
    var extraCategoryIds: [String]   // ID kategori tambahan
    var spent: Decimal = 0           // Virtual — dihitung di runtime

    // Semua ID kategori yang dicakup budget ini
    var allCategoryIds: [String] { ... }
}
```

**Aturan group budget:**
- Jika `groupName != nil` → ini group budget, tampilkan icon `slider.horizontal.3`.
- `recalculateBudgets()` menjumlahkan spent dari **semua** category ID dalam `allCategoryIds`.
- `BudgetRowView` menampilkan `groupName` sebagai judul + daftar nama kategori sebagai subtitle.
- Field `groupName` dan `extraCategoryIds` punya default `nil`/`[]` → backward compatible dengan budget lama.

---

## Auto-Budget Wizard (50/30/20)

Wizard membuat **2 group budget**, bukan 8+ per-kategori:

| Group | % | Kategori |
|---|---|---|
| Kebutuhan Pokok | 50% | Makan & Minum, Transportasi, Kesehatan, Rumah & Tagihan, Pendidikan |
| Keinginan | 30% | Hiburan, Belanja, Langganan Digital, Perjalanan, Perlengkapan Kerja |
| Tabungan | 20% | Tidak dibuat sebagai budget (hanya info) |

Wizard **menghapus semua budget lama** bulan tersebut dulu, baru buat 2 group budget baru.

---

## Dashboard — Saldo Kumulatif

`DashboardViewModel` memiliki dua properti saldo:

| Properti | Definisi | Digunakan di |
|---|---|---|
| `netBalance` | income - expense bulan ini | (internal, tidak ditampilkan utama) |
| `cumulativeBalance` | Sum semua transaksi dari awal s.d. akhir bulan terpilih | Kartu utama "Total Saldo" |

Saldo otomatis terbawa antar bulan — tidak perlu input ulang. Badge Masuk/Keluar tetap menampilkan angka bulan berjalan.

---

## Halaman Transaksi — Filter Bulan

`TransactionListView` default menampilkan bulan saat ini:
- Navigasi `< Agustus 2026 >` di atas daftar.
- Tombol "Semua Bulan" / "Bulan Ini" untuk toggle.
- **iOS**: swipe kiri → hapus (konfirmasi alert), swipe kanan → edit.
- **Mac**: klik kanan → menu "Edit Transaksi" / "Hapus Transaksi".

---

## Hapus Budget

- `BudgetRowView(budget:, allCategories:, onDelete:)` — parameter `onDelete` opsional.
- Jika `onDelete != nil`, ikon 🗑 merah ditampilkan di kartu.
- Penghapusan selalu melalui konfirmasi alert di `BudgetView`.
- Mac: klik kanan → "Hapus" juga lewat konfirmasi yang sama.

---

## Pencegahan dan Pembersihan Duplikat

Seeding di `CashWayApp.swift` menggunakan `async/await` + `MainActor.run`:
1. Cek Firestore (`categories` collection, limit 1).
2. Jika kosong → `seedCategories()` + `seedWallets()`.
3. ID deterministik per-user → seed ulang tidak buat duplikat.

Tombol **"Bersihkan Data Duplikat"** di Settings → `DataStore.cleanupDuplicates()`:
- Async, batch Firestore commit.
- Duplikat kategori: sama `name` + `type`.
- Duplikat wallet: sama `name`.

---

## Sertifikat Sideload (iOS)

Banner peringatan **hanya** tampil saat `daysUntilExpiration <= 1`:

```swift
if let days = vm.daysUntilExpiration, days <= 1 {
    SlideInCard(index: 1) { expirationBanner(days: days) }
}
```

Jangan ubah kondisi ini menjadi lebih longgar — banner tidak boleh muncul setiap hari.

---

## Aturan Concurrency Swift 6

- `DataStore`, view model, `NotificationManager`, `PDFExporter` → `@MainActor`.
- Callback Firestore yang async harus balik ke `MainActor` via `await MainActor.run { }`.
- Model DTO harus `nonisolated` agar bisa di-encode/decode Firestore di luar MainActor.
- Jangan hapus `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` untuk sembunyikan warning.

---

## Firestore Query

- **Hanya** gunakan `.whereField("userId", isEqualTo: uid)` — tidak ada composite index.
- Sort dilakukan client-side.
- Jangan buat Firestore index baru tanpa kebutuhan jelas.

---

## Aturan UI

- Semua teks UI dalam **Bahasa Indonesia**.
- Warna via `Color.cw…` (ColorExtensions.swift).
- `#if os(iOS)` / `#if os(macOS)` untuk perbedaan platform.
- Pertahankan dark premium design; gunakan komponen existing (`SlideInCard`, `AnimatedNumberText`, dll).
- Jangan tambah dependensi pihak ketiga tanpa persetujuan. Firebase + Google Sign-In sudah disetujui.

---

## Cara Kerja Aman

1. Baca file terkait sebelum edit.
2. Buat perubahan sekecil mungkin.
3. Jangan gunakan `git reset`, `checkout --`, atau operasi destruktif database.
4. Build setelah perubahan; bedakan error compiler dari warning Xcode.
5. Laporkan file yang diubah dan hasil build.
