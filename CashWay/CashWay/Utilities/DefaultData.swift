import Foundation

// ============================================================
// MARK: - DefaultData
// Data awal yang di-seed saat pertama kali app dibuka.
// Berisi kategori preset dan wallet default.
// ============================================================

nonisolated struct DefaultData {

    // MARK: - Expense Categories
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
        ("Equipment Kreatif",  "camera.fill",                "#00C9A7", 9),
        ("Software & Tools",   "laptopcomputer",             "#2D3436", 10),
        ("Perjalanan",         "airplane",                   "#74B9FF", 11),
        ("Hadiah",             "gift.fill",                  "#FD79A8", 12),
        ("Lainnya",            "ellipsis.circle.fill",       "#8B8FA8", 13),
    ]}

    // MARK: - Income Categories
    static var incomeCategories: [(name: String, icon: String, color: String, order: Int)] {[
        ("Gaji Kantor",          "building.2.fill",           "#00C9A7", 0),
        ("Freelance / Project",  "video.fill",                "#F4A261", 1),
        ("Bonus",                "star.fill",                 "#FDCB6E", 2),
        ("Investasi",            "chart.line.uptrend.xyaxis", "#55EFC4", 3),
        ("Hadiah / Uang Masuk",  "gift.fill",                 "#FD79A8", 4),
        ("Dari Orang Tua",       "figure.2.arms.open",        "#ff33aa", 5),
        ("Lainnya",              "ellipsis.circle.fill",      "#8B8FA8", 6),
    ]}

    // MARK: - Default Wallets
    static var defaultWallets: [(name: String, type: WalletType, icon: String, color: String, isDefault: Bool)] {[
        ("Tunai",  .cash,    "banknote.fill",         "#00C9A7", true),
        ("Bank",   .bank,    "building.columns.fill", "#54A0FF", false),
        ("GoPay",  .ewallet, "g.circle.fill",         "#4CAF82", false),
        ("OVO",    .ewallet, "o.circle.fill",         "#A29BFE", false),
    ]}

    // MARK: - Budget Recommendations
    static func recommendedBudgets(salary: Decimal) -> [(categoryName: String, amount: Decimal, ratio: Double)] {[
        ("Makan & Minum",      salary * Decimal(0.25), 0.25),
        ("Transportasi",       salary * Decimal(0.10), 0.10),
        ("Rumah & Tagihan",    salary * Decimal(0.15), 0.15),
        ("Belanja",            salary * Decimal(0.10), 0.10),
        ("Hiburan",            salary * Decimal(0.05), 0.05),
        ("Equipment Kreatif",  salary * Decimal(0.10), 0.10),
        ("Langganan Digital",  salary * Decimal(0.05), 0.05),
        ("Lainnya",            salary * Decimal(0.05), 0.05),
    ]}
}
