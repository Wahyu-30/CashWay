import Foundation

nonisolated struct Budget: Identifiable, Codable, Equatable, Hashable {
    var id: String
    var userId: String       // Stempel pemilik: UID Google pengguna
    var amount: Decimal
    var month: Int
    var year: Int

    // We store the full category object here for easier querying in NoSQL.
    var category: Category?

    // Group budget support — satu budget bisa mencakup banyak kategori
    var groupName: String?          // Misal: "Kebutuhan Pokok (50%)" — jika nil, ini bukan group budget
    var extraCategoryIds: [String]  // ID kategori tambahan di luar `category`

    // Virtual property, not stored in DB, calculated at runtime
    var spent: Decimal = 0

    // Semua ID kategori yang masuk dalam budget ini (primary + extras)
    var allCategoryIds: [String] {
        var ids: [String] = []
        if let primaryId = category?.id { ids.append(primaryId) }
        ids.append(contentsOf: extraCategoryIds)
        return ids
    }

    init(
        id: String = UUID().uuidString,
        userId: String = "",
        amount: Decimal,
        month: Int,
        year: Int,
        category: Category? = nil,
        groupName: String? = nil,
        extraCategoryIds: [String] = []
    ) {
        self.id = id
        self.userId = userId
        self.amount = amount
        self.month = month
        self.year = year
        self.category = category
        self.groupName = groupName
        self.extraCategoryIds = extraCategoryIds
    }
    
    var remaining: Decimal {
        amount - spent
    }
    
    var progress: Double {
        if amount == 0 { return spent > 0 ? 1.0 : 0.0 }
        return NSDecimalNumber(decimal: spent / amount).doubleValue
    }
    
    var percentage: Double { progress }
    
    var isOverBudget: Bool { spent > amount }
    
    var isNearLimit: Bool {
        guard !isOverBudget, amount > 0 else { return false }
        return progress >= 0.8
    }
    
    enum BudgetStatus {
        case ok, nearLimit, overBudget
        var label: String {
            switch self {
            case .ok:          return "Aman"
            case .nearLimit:   return "Hampir Habis"
            case .overBudget:  return "Melewati Budget"
            }
        }
        var icon: String {
            switch self {
            case .ok:          return "checkmark.circle.fill"
            case .nearLimit:   return "exclamationmark.circle.fill"
            case .overBudget:  return "xmark.circle.fill"
            }
        }
        var colorHex: String {
            switch self {
            case .ok:          return "#4CAF82"
            case .nearLimit:   return "#F4A261"
            case .overBudget:  return "#FF6B6B"
            }
        }
    }
    
    var status: BudgetStatus {
        if isOverBudget { return .overBudget }
        if isNearLimit  { return .nearLimit }
        return .ok
    }
}
