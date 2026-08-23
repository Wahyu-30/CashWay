import SwiftData
import Foundation

// ============================================================
// MARK: - Category Model
// Kategori untuk transaksi (Makan, Transport, Gaji, Freelance, dll)
// ============================================================

@Model
final class Category {

    @Attribute(.unique) var id: UUID
    var name: String
    var icon: String         // SF Symbol name, contoh: "fork.knife"
    var colorHex: String     // Hex color, contoh: "#FF9F43"
    var type: CategoryType   // .income atau .expense
    var isDefault: Bool      // Jika true, tidak bisa dihapus user
    var sortOrder: Int       // Urutan tampil di UI

    @Relationship(deleteRule: .nullify)
    var transactions: [Transaction] = []

    @Relationship(deleteRule: .cascade)
    var budgets: [Budget] = []

    init(
        name: String,
        icon: String,
        colorHex: String,
        type: CategoryType,
        isDefault: Bool = false,
        sortOrder: Int = 99
    ) {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
        self.type = type
        self.isDefault = isDefault
        self.sortOrder = sortOrder
    }

    enum CategoryType: String, Codable, CaseIterable {
        case income  = "income"
        case expense = "expense"

        var displayName: String {
            switch self {
            case .income:  return "Pemasukan"
            case .expense: return "Pengeluaran"
            }
        }
    }
}
