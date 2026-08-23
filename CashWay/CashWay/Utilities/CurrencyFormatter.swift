import Foundation

// ============================================================
// MARK: - CurrencyFormatter
// SELALU gunakan ini untuk format angka ke Rupiah.
// JANGAN format angka Rupiah secara manual di tempat lain.
// ============================================================

struct CurrencyFormatter {

    // Formatter utama untuk IDR
    private static let formatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle         = .currency
        f.currencyCode        = "IDR"
        f.currencySymbol      = "Rp "
        f.groupingSeparator   = "."
        f.decimalSeparator    = ","
        f.maximumFractionDigits = 0
        f.minimumFractionDigits = 0
        return f
    }()

    // MARK: - Format ke String

    /// Format Decimal ke string Rupiah lengkap.
    /// Contoh: Decimal(1250000) → "Rp 1.250.000"
    static func format(_ amount: Decimal) -> String {
        formatter.string(from: amount as NSDecimalNumber) ?? "Rp 0"
    }

    /// Format Double ke string Rupiah lengkap.
    static func format(_ amount: Double) -> String {
        format(Decimal(amount))
    }

    /// Format kompak untuk angka besar.
    /// Contoh: 1_200_000 → "Rp 1,2Jt" | 500_000 → "Rp 500rb"
    static func formatCompact(_ amount: Decimal) -> String {
        let d = NSDecimalNumber(decimal: amount).doubleValue
        switch d {
        case 1_000_000_000...:
            return String(format: "Rp %.1fM", d / 1_000_000_000)
        case 1_000_000...:
            return String(format: "Rp %.1fJt", d / 1_000_000)
        case 1_000...:
            return String(format: "Rp %.0frb", d / 1_000)
        default:
            return format(amount)
        }
    }

    // MARK: - Parse dari String

    /// Parse input teks ke Decimal.
    /// Hapus semua karakter non-digit lalu konversi.
    /// Contoh: "Rp 1.250.000" → Decimal(1250000)
    static func parse(_ text: String) -> Decimal {
        let digits = text.filter { $0.isNumber }
        return Decimal(string: digits) ?? Decimal(0)
    }

    // MARK: - Signed Format (untuk tampilan +/-)

    /// Format dengan tanda + atau - berdasarkan tipe transaksi.
    /// Contoh income: "+Rp 4.500.000" | expense: "-Rp 45.000"
    static func formatSigned(_ amount: Decimal, type: Transaction.TransactionType) -> String {
        let base = format(amount)
        switch type {
        case .income:   return "+\(base)"
        case .expense:  return "-\(base)"
        case .transfer: return base
        }
    }
}
