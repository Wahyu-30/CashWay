import SwiftUI

// ============================================================
// MARK: - Color Extensions
// Design system CashWay. Selalu gunakan color ini, jangan hardcode hex di View.
// ============================================================

extension Color {

    // MARK: - Background Hierarchy (dari paling gelap ke terang)
    static let cwBackground      = Color(hex: "#0F0F14")  // Background utama
    static let cwSurface         = Color(hex: "#1A1A2E")  // Card, sheet
    static let cwSurfaceElevated = Color(hex: "#242438")  // Modal, elevated

    // MARK: - Accent & Status
    static let cwAccent    = Color(hex: "#00C9A7")  // Teal — CTA, active state
    static let cwIncome    = Color(hex: "#4CAF82")  // Hijau — pemasukan
    static let cwExpense   = Color(hex: "#FF6B6B")  // Coral — pengeluaran
    static let cwWarning   = Color(hex: "#F4A261")  // Amber — peringatan / freelance
    static let cwFreelance = Color(hex: "#F4A261")  // Amber — warna khusus freelance

    // MARK: - Text
    static let cwTextPrimary   = Color.white
    static let cwTextSecondary = Color(hex: "#8B8FA8")
    static let cwPlaceholder   = Color(hex: "#4A4A6A")

    // MARK: - Border
    static let cwBorder = Color(hex: "#2A2A3E")

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
