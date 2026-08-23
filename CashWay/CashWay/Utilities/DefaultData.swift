import Foundation
import SwiftData

// ============================================================
// MARK: - DefaultData
// Data awal yang di-seed saat pertama kali app dibuka.
// Berisi kategori preset dan wallet default.
// seedIfNeeded() dipanggil SATU KALI saat app launch.
// ============================================================

struct DefaultData {

    // MARK: - Expense Categories
    // Kategori pengeluaran preset. isDefault = true → tidak bisa dihapus user.
    static var expenseCategories: [(name: String, icon: String, color: String, order: Int)] {[
        ("Makan & Minum",      "fork.knife",                 "#FF9F43", 0),
        ("Transportasi",       "car.fill",                   "#54A0FF", 1),
        ("Belanja",            "bag.fill",                   "#FF6B6B", 2),
        ("Kesehatan",          "cross.fill",                 "#FF6B81", 3),
        ("Hiburan",            "tv.fill",                    "#A29BFE", 4),
        ("Langganan Digital",  "play.rectangle.fill",        "#6C5CE7", 5),
        ("Rumah & Tagihan",    "house.fill",                 "#00CEC9", 6),
        ("Pendidikan",         "book.fill",                  "#FDCB6E", 7),
        ("Perlengkapan Kerja", "briefcase.fill",             "#636E72", 8),
        // Khusus untuk videografer & editor:
        ("Equipment Kreatif",  "camera.fill",                "#00C9A7", 9),
        ("Software & Tools",   "laptopcomputer",             "#2D3436", 10),
        ("Perjalanan",         "airplane",                   "#74B9FF", 11),
        ("Hadiah",             "gift.fill",                  "#FD79A8", 12),
        ("Lainnya",            "ellipsis.circle.fill",       "#8B8FA8", 13),
    ]}

    // MARK: - Income Categories
    // Kategori pemasukan preset.
    static var incomeCategories: [(name: String, icon: String, color: String, order: Int)] {[
        ("Gaji Kantor",          "building.2.fill",           "#00C9A7", 0),
        ("Freelance / Project",  "video.fill",                "#F4A261", 1),  // Icon video untuk videografer
        ("Bonus",                "star.fill",                 "#FDCB6E", 2),
        ("Investasi",            "chart.line.uptrend.xyaxis", "#55EFC4", 3),
        ("Hadiah / Uang Masuk",  "gift.fill",                 "#FD79A8", 4),
        ("Lainnya",              "ellipsis.circle.fill",      "#8B8FA8", 5),
    ]}

    // MARK: - Default Wallets
    static var defaultWallets: [(name: String, type: Wallet.WalletType, icon: String, color: String, isDefault: Bool)] {[
        ("Tunai",  .cash,    "banknote.fill",         "#00C9A7", true),
        ("Bank",   .bank,    "building.columns.fill", "#54A0FF", false),
        ("GoPay",  .ewallet, "g.circle.fill",         "#4CAF82", false),
        ("OVO",    .ewallet, "o.circle.fill",         "#A29BFE", false),
    ]}

    // MARK: - Seed Function
    /// Panggil di CashWayApp.swift → .onAppear { DefaultData.seedIfNeeded(context: ...) }
    /// Fungsi ini cek dulu apakah data sudah ada, jika ya → skip.
    static func seedIfNeeded(context: ModelContext) {
        // Cek apakah kategori sudah ada
        let descriptor = FetchDescriptor<Category>()
        guard (try? context.fetch(descriptor))?.isEmpty == true else { return }

        // Seed expense categories
        for cat in expenseCategories {
            context.insert(Category(
                name:      cat.name,
                icon:      cat.icon,
                colorHex:  cat.color,
                type:      .expense,
                isDefault: true,
                sortOrder: cat.order
            ))
        }

        // Seed income categories
        for cat in incomeCategories {
            context.insert(Category(
                name:      cat.name,
                icon:      cat.icon,
                colorHex:  cat.color,
                type:      .income,
                isDefault: true,
                sortOrder: cat.order
            ))
        }

        // Seed wallets
        for (i, w) in defaultWallets.enumerated() {
            context.insert(Wallet(
                name:           w.name,
                type:           w.type,
                icon:           w.icon,
                colorHex:       w.color,
                initialBalance: 0,
                isDefault:      w.isDefault,
                sortOrder:      i
            ))
        }

        try? context.save()
    }

    // MARK: - Budget Recommendations
    // Rekomendasi budget berdasarkan gaji Rp 4.500.000/bulan.
    // Tampilkan ini di onboarding atau saat user pertama set budget.
    static func recommendedBudgets(salary: Decimal) -> [(categoryName: String, amount: Decimal, ratio: Double)] {[
        ("Makan & Minum",      salary * Decimal(0.25), 0.25),
        ("Transportasi",       salary * Decimal(0.10), 0.10),
        ("Rumah & Tagihan",    salary * Decimal(0.15), 0.15),
        ("Belanja",            salary * Decimal(0.10), 0.10),
        ("Hiburan",            salary * Decimal(0.05), 0.05),
        ("Equipment Kreatif",  salary * Decimal(0.10), 0.10),
        ("Langganan Digital",  salary * Decimal(0.05), 0.05),
        ("Lainnya",            salary * Decimal(0.05), 0.05),
        // 15% disisihkan untuk tabungan (tidak masuk budget pengeluaran)
    ]}
}
