import Foundation

enum CategoryType: String, Codable {
    case income = "income"
    case expense = "expense"
}

struct Category: Identifiable, Codable, Equatable, Hashable {
    var id: String
    var name: String
    var icon: String
    var colorHex: String
    var type: CategoryType
    var isDefault: Bool
    var sortOrder: Int

    init(
        id: String = UUID().uuidString,
        name: String,
        icon: String,
        colorHex: String,
        type: CategoryType,
        isDefault: Bool = false,
        sortOrder: Int = 99
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
        self.type = type
        self.isDefault = isDefault
        self.sortOrder = sortOrder
    }
}
