import SwiftData
import Foundation

// ============================================================
// MARK: - Wallet Model
// Dompet atau akun keuangan (Tunai, BCA, GoPay, OVO, dll)
// PENTING: currentBalance adalah computed property, TIDAK disimpan di DB
// ============================================================

@Model
final class Wallet {

    @Attribute(.unique) var id: UUID
    var name: String
    var type: WalletType
    var icon: String         // SF Symbol name
    var colorHex: String     // Hex color
    var initialBalance: Decimal  // Saldo awal saat wallet dibuat
    var isDefault: Bool      // Wallet default untuk transaksi baru
    var sortOrder: Int

    @Relationship(deleteRule: .nullify)
    var transactions: [Transaction] = []

    init(
        name: String,
        type: WalletType,
        icon: String,
        colorHex: String,
        initialBalance: Decimal = 0,
        isDefault: Bool = false,
        sortOrder: Int = 99
    ) {
        self.id = UUID()
        self.name = name
        self.type = type
        self.icon = icon
        self.colorHex = colorHex
        self.initialBalance = initialBalance
        self.isDefault = isDefault
        self.sortOrder = sortOrder
    }

    // MARK: - Computed Balance
    // Hitung saldo saat ini dari initialBalance + semua transaksi
    // Ini COMPUTED, tidak perlu & tidak boleh disimpan di database
    var currentBalance: Decimal {
        var balance = initialBalance
        for t in transactions {
            switch t.type {
            case .income:   balance += t.amount
            case .expense:  balance -= t.amount
            case .transfer: balance -= t.amount  // Transfer keluar dari wallet ini
            }
        }
        return balance
    }

    enum WalletType: String, Codable, CaseIterable {
        case cash       = "cash"
        case bank       = "bank"
        case ewallet    = "ewallet"
        case creditCard = "creditCard"

        var displayName: String {
            switch self {
            case .cash:       return "Tunai"
            case .bank:       return "Bank"
            case .ewallet:    return "E-Wallet"
            case .creditCard: return "Kartu Kredit"
            }
        }

        var icon: String {
            switch self {
            case .cash:       return "banknote.fill"
            case .bank:       return "building.columns.fill"
            case .ewallet:    return "iphone"
            case .creditCard: return "creditcard.fill"
            }
        }
    }
}
