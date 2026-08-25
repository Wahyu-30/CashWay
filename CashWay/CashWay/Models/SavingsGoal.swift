import Foundation
import SwiftData

@Model
final class SavingsGoal {
    var id: UUID = UUID()
    var name: String = ""
    var targetAmount: Decimal = 0
    var currentAmount: Decimal = 0
    var targetDate: Date? = nil
    var icon: String = "target"
    var colorHex: String = "#1c6cff"
    
    // Status apakah goal sudah tercapai
    var isAchieved: Bool {
        currentAmount >= targetAmount && targetAmount > 0
    }
    
    // Persentase progress (0.0 - 1.0)
    var progress: Double {
        guard targetAmount > 0 else { return 0 }
        let ratio = currentAmount / targetAmount
        return min(NSDecimalNumber(decimal: ratio).doubleValue, 1.0)
    }

    init(
        name: String,
        targetAmount: Decimal,
        currentAmount: Decimal = 0,
        targetDate: Date? = nil,
        icon: String = "target",
        colorHex: String = "#1c6cff"
    ) {
        self.name = name
        self.targetAmount = targetAmount
        self.currentAmount = currentAmount
        self.targetDate = targetDate
        self.icon = icon
        self.colorHex = colorHex
    }
}
