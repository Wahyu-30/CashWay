import Foundation

enum WalletType: String, Codable {
    case cash = "cash"
    case bank = "bank"
    case ewallet = "ewallet"
    case credit = "credit"
}

struct Wallet: Identifiable, Codable, Equatable, Hashable {
    var id: String
    var name: String
    var type: WalletType
    var icon: String
    var colorHex: String
    var initialBalance: Decimal
    var isDefault: Bool
    var sortOrder: Int

    init(
        id: String = UUID().uuidString,
        name: String,
        type: WalletType,
        icon: String,
        colorHex: String,
        initialBalance: Decimal = 0,
        isDefault: Bool = false,
        sortOrder: Int = 99
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.icon = icon
        self.colorHex = colorHex
        self.initialBalance = initialBalance
        self.isDefault = isDefault
        self.sortOrder = sortOrder
    }
}
