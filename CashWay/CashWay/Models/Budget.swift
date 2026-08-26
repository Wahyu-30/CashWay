import Foundation

struct Budget: Identifiable, Codable, Equatable, Hashable {
    var id: String
    var amount: Decimal
    var month: Int
    var year: Int
    
    // We store the full category object here for easier querying in NoSQL.
    var category: Category?
    
    // Virtual property, not stored in DB, calculated at runtime
    var spent: Decimal = 0

    init(
        id: String = UUID().uuidString,
        amount: Decimal,
        month: Int,
        year: Int,
        category: Category? = nil
    ) {
        self.id = id
        self.amount = amount
        self.month = month
        self.year = year
        self.category = category
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
