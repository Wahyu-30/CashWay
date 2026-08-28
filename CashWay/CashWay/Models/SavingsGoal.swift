import Foundation

struct SavingsGoal: Identifiable, Codable, Equatable, Hashable {
    var id: String
    var userId: String       // Stempel pemilik: UID Google pengguna
    var name: String
    var targetAmount: Decimal
    var currentAmount: Decimal
    var targetDate: Date?
    var icon: String
    var colorHex: String
    var createdAt: Date

    init(
        id: String = UUID().uuidString,
        userId: String = "",
        name: String,
        targetAmount: Decimal,
        currentAmount: Decimal = 0,
        targetDate: Date? = nil,
        icon: String = "target",
        colorHex: String = "#1c6cff",
        createdAt: Date = .now
    ) {
        self.id = id
        self.userId = userId
        self.name = name
        self.targetAmount = targetAmount
        self.currentAmount = currentAmount
        self.targetDate = targetDate
        self.icon = icon
        self.colorHex = colorHex
        self.createdAt = createdAt
    }
    
    var progress: Double {
        if targetAmount == 0 { return 0 }
        return min(NSDecimalNumber(decimal: currentAmount / targetAmount).doubleValue, 1.0)
    }
}
