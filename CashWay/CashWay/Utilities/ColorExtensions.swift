import SwiftUI

// ============================================================
// MARK: - Color Extensions
// Design system CashWay. Selalu gunakan color ini, jangan hardcode hex di View.
// ============================================================

extension Color {

    // MARK: - Background Hierarchy (dari paling gelap ke terang)
    static let cwBackground      = Color(hex: "#000814")  // Midnight Canvas
    static let cwSurface         = Color(hex: "#010d1e")  // Deep Surface
    static let cwSurfaceElevated = Color(hex: "#001533")  // Indigo Surface

    // MARK: - Accent & Status
    static let cwAccent    = Color(hex: "#1c6cff")  // Signal Blue — CTA, active state
    static let cwIncome    = Color(hex: "#00cc4b")  // Tag Lime — pemasukan
    static let cwExpense   = Color(hex: "#ff4433")  // Tag Coral — pengeluaran
    static let cwWarning   = Color(hex: "#ffcc02")  // Tag Sunflower — peringatan
    static let cwFreelance = Color(hex: "#ff8833")  // Tag Tangerine — warna khusus freelance

    // MARK: - Text
    static let cwTextPrimary   = Color.white
    static let cwTextSecondary = Color(hex: "#748399")  // Muted blue-gray
    static let cwPlaceholder   = Color(hex: "#34455E")

    // MARK: - Border
    static let cwBorder = Color(hex: "#10213E")

    // MARK: - Hex Initializer
    // Mengizinkan Color(hex: "#FF6B6B")
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:  (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:  (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:  (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red:     Double(r) / 255,
            green:   Double(g) / 255,
            blue:    Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// ============================================================
// MARK: - Spacing Constants
// Selalu gunakan ini untuk padding/spacing, jangan hardcode angka.
// ============================================================

enum CWSpacing {
    static let xs:  CGFloat = 4
    static let sm:  CGFloat = 8
    static let md:  CGFloat = 16
    static let lg:  CGFloat = 24
    static let xl:  CGFloat = 32
    static let xxl: CGFloat = 48
}

// ============================================================
// MARK: - Corner Radius Constants
// ============================================================

enum CWRadius {
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
}
