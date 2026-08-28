import Foundation

struct Transaction: Identifiable, Codable, Equatable, Hashable {
    
    enum IncomeTag: String, Codable, CaseIterable {
        case salary = "Gaji Utama"
        case parents = "Dari Orang Tua"
        case business = "Usaha / Bisnis"
        case investment = "Investasi"
        case other = "Lainnya"
        
        var displayName: String { rawValue }
        
        var icon: String {
            switch self {
            case .salary:     return "building.2.fill"
            case .parents:    return "figure.2.arms.open"
            case .business:   return "video.fill"
            case .investment: return "chart.line.uptrend.xyaxis"
            case .other:      return "ellipsis.circle.fill"
            }
        }
        
        var colorHex: String {
            switch self {
            case .salary:     return "#00C9A7"
            case .parents:    return "#ff33aa"
            case .business:   return "#1c6cff"
            case .investment: return "#9019e6"
            case .other:      return "#8B8FA8"
            }
        }
    }

    enum TransactionType: String, Codable, CaseIterable {
        case income   = "income"
        case expense  = "expense"
        case transfer = "transfer"
        
        var displayName: String {
            switch self {
            case .income:   return "Pemasukan"
            case .expense:  return "Pengeluaran"
            case .transfer: return "Transfer"
            }
        }
        
        var icon: String {
            switch self {
            case .income:   return "arrow.down.left.circle.fill"
            case .expense:  return "arrow.up.right.circle.fill"
            case .transfer: return "arrow.left.arrow.right.circle.fill"
            }
        }
    }

    var id: String
    var userId: String       // Stempel pemilik: UID Google pengguna
    var amount: Decimal
    var type: TransactionType
    var date: Date
    var note: String
    
    var category: Category?
    var wallet: Wallet?
    var incomeTag: IncomeTag?
    
    var createdAt: Date

    init(
        id: String = UUID().uuidString,
        userId: String = "",
        amount: Decimal,
        type: TransactionType,
        date: Date,
        note: String = "",
        category: Category? = nil,
        wallet: Wallet? = nil,
        incomeTag: IncomeTag? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.userId = userId
        self.amount = amount
        self.type = type
        self.date = date
        self.note = note
        self.category = category
        self.wallet = wallet
        self.incomeTag = incomeTag
        self.createdAt = createdAt
    }
}
