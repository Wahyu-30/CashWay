import SwiftData
import Foundation

// ============================================================
// MARK: - Budget Model
// Batas pengeluaran per kategori per bulan
// Contoh: Budget "Makan" bulan Agustus 2026 = Rp 1.000.000
// ============================================================

@Model
final class Budget {

    @Attribute(.unique) var id: UUID
    var amount: Decimal    // Batas maksimal (contoh: 1_000_000)
    var month: Int         // 1-12
    var year: Int          // Contoh: 2026

    @Relationship(deleteRule: .nullify)
    var category: Category?

    init(amount: Decimal, month: Int, year: Int, category: Category? = nil) {
        self.id = UUID()
        self.amount = amount
        self.month = month
        self.year = year
        self.category = category
    }

    // MARK: - Computed Properties
    // Semua ini COMPUTED dari data transaksi, TIDAK disimpan di database

    /// Total yang sudah dibelanjakan untuk budget ini
    var spent: Decimal {
        guard let category = category else { return 0 }
        let cal = Calendar.current
        return category.transactions
            .filter { t in
                t.type == .expense &&
                cal.component(.month, from: t.date) == month &&
                cal.component(.year, from: t.date) == year
            }
            .reduce(Decimal(0)) { $0 + $1.amount }
    }

    var remaining: Decimal { amount - spent }

    /// Persentase penggunaan (0.0 = 0%, 1.0 = 100%, >1.0 = over budget)
    var percentage: Double {
        guard amount > 0 else { return 0 }
        return Double(truncating: (spent / amount) as NSDecimalNumber)
    }

    var isOverBudget: Bool { spent > amount }
    var isNearLimit: Bool  { percentage >= 0.8 && !isOverBudget }
    var isSafe: Bool       { percentage < 0.8 }

    var status: BudgetStatus {
        if isOverBudget { return .overBudget }
        if isNearLimit  { return .nearLimit }
        return .safe
    }

    // MARK: - Status Enum
    enum BudgetStatus {
        case safe        // < 80% terpakai
        case nearLimit   // 80% - 100%
        case overBudget  // > 100%

        var colorHex: String {
            switch self {
            case .safe:        return "#00C9A7"   // Teal
            case .nearLimit:   return "#F4A261"   // Amber
            case .overBudget:  return "#FF6B6B"   // Coral/Merah
            }
        }

        var icon: String {
            switch self {
            case .safe:        return "checkmark.circle.fill"
            case .nearLimit:   return "exclamationmark.triangle.fill"
            case .overBudget:  return "xmark.circle.fill"
            }
        }

        var label: String {
            switch self {
            case .safe:        return "Aman"
            case .nearLimit:   return "Hampir Habis"
            case .overBudget:  return "Terlampaui"
            }
        }
    }
}
