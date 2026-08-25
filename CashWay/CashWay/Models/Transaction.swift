import SwiftData
import Foundation

// ============================================================
// MARK: - Transaction Model
// Menyimpan satu transaksi keuangan (pemasukan/pengeluaran/transfer)
// PENTING: amount SELALU positif. Positif/negatif ditentukan dari 'type'
// ============================================================

@Model
final class Transaction {

    // MARK: - Properties
    @Attribute(.unique) var id: UUID
    var amount: Decimal          // Selalu positif, dalam Rupiah
    var type: TransactionType
    var date: Date
    var note: String
    var createdAt: Date
    var incomeTag: IncomeTag?    // HANYA untuk type == .income

    // MARK: - Relationships
    @Relationship(deleteRule: .nullify)
    var category: Category?

    @Relationship(deleteRule: .nullify)
    var wallet: Wallet?

    // MARK: - Init
    init(
        amount: Decimal,
        type: TransactionType,
        date: Date = .now,
        note: String = "",
        category: Category? = nil,
        wallet: Wallet? = nil,
        incomeTag: IncomeTag? = nil
    ) {
        self.id = UUID()
        self.amount = amount
        self.type = type
        self.date = date
        self.note = note
        self.category = category
        self.wallet = wallet
        self.incomeTag = incomeTag
        self.createdAt = .now
    }

    // MARK: - TransactionType
    // Tipe transaksi: pemasukan, pengeluaran, atau transfer antar wallet
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
            case .income:   return "arrow.down.circle.fill"
            case .expense:  return "arrow.up.circle.fill"
            case .transfer: return "arrow.left.arrow.right.circle.fill"
            }
        }

        var color: String {
            switch self {
            case .income:   return "#4CAF82"
            case .expense:  return "#FF6B6B"
            case .transfer: return "#8B8FA8"
            }
        }
    }

    // MARK: - IncomeTag
    // KHUSUS untuk income — membedakan gaji tetap vs freelance
    // Way (user) punya: gaji kantor Rp 4.5Jt/bulan + freelance videografi variabel
    enum IncomeTag: String, Codable, CaseIterable {
        case salary    = "salary"     // Gaji tetap dari kantor
        case freelance = "freelance"  // Project/freelance videografi
        case bonus     = "bonus"      // Bonus / THR
        case rental    = "rental"     // Penyewaan alat kamera/video
        case invest    = "invest"     // Hasil investasi
        case parents   = "parents"    // Pemberian Orang Tua
        case other     = "other"      // Pemasukan lainnya

        var displayName: String {
            switch self {
            case .salary:    return "Gaji Kantor"
            case .freelance: return "Freelance / Project"
            case .bonus:     return "Bonus / THR"
            case .rental:    return "Sewa Alat"
            case .invest:    return "Investasi"
            case .parents:   return "Dari Orang Tua"
            case .other:     return "Lainnya"
            }
        }

        var icon: String {
            switch self {
            case .salary:    return "building.2.fill"
            case .freelance: return "video.fill"
            case .bonus:     return "gift.fill"
            case .rental:    return "camera.fill"
            case .invest:    return "chart.line.uptrend.xyaxis"
            case .parents:   return "figure.2.arms.open"
            case .other:     return "dollarsign.circle.fill"
            }
        }

        var colorHex: String {
            switch self {
            case .salary:    return "#00C9A7"
            case .freelance: return "#F4A261"
            case .bonus:     return "#E76F51"
            case .rental:    return "#2A9D8F"
            case .invest:    return "#264653"
            case .other:     return "#8B8FA8"
            }
        }
    }
}
