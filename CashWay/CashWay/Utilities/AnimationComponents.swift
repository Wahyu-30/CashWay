import SwiftUI
import Combine

// ============================================================
// MARK: - AnimatedNumberText
// Komponen angka yang "counting up/down" saat nilai berubah.
// Gunakan ini untuk semua angka Rupiah di aplikasi.
// ============================================================

struct AnimatedNumberText: View {
    let value: Decimal
    let color: Color
    let font: Font

    @State private var displayedValue: Double = 0

    var body: some View {
        Text(CurrencyFormatter.format(Decimal(displayedValue)))
            .font(font)
            .foregroundStyle(color)
            .monospacedDigit()
            .contentTransition(.numericText(value: displayedValue))
            .onAppear {
                withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                    displayedValue = Double(truncating: value as NSDecimalNumber)
                }
            }
            .onChange(of: value) { _, newValue in
                withAnimation(.spring(response: 0.6, dampingFraction: 0.75)) {
                    displayedValue = Double(truncating: newValue as NSDecimalNumber)
                }
            }
    }
}

// ============================================================
// MARK: - SlideInCard
// Wrapper yang memberi efek slide-up + fade saat view muncul.
// ============================================================

struct SlideInCard<Content: View>: View {
    let index: Int
    let content: Content

    @State private var appeared = false

    init(index: Int = 0, @ViewBuilder content: () -> Content) {
        self.index = index
        self.content = content()
    }

    var body: some View {
        content
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 40)
            .onAppear {
                withAnimation(
                    .spring(response: 0.75, dampingFraction: 0.8)
                    .delay(Double(index) * 0.12)
                ) {
                    appeared = true
                }
            }
    }
}

// ============================================================
// MARK: - PulsingDot
// Titik kecil berdenyut — untuk indikator status aktif.
// ============================================================

struct PulsingDot: View {
    let color: Color
    @State private var scale: CGFloat = 1.0

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 7, height: 7)
            .scaleEffect(scale)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                    scale = 1.4
                }
            }
    }
}

// ============================================================
// MARK: - ShimmerModifier
// Efek loading shimmer untuk skeleton placeholder.
// ============================================================

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = -1

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geo in
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0),
                            Color.white.opacity(0.08),
                            Color.white.opacity(0)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .offset(x: phase * geo.size.width * 2)
                }
                .allowsHitTesting(false)
            )
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}

// ============================================================
// MARK: - TapScaleButton
// Tombol dengan efek "pijat" saat ditekan (scale down + bounce).
// ============================================================

struct TapScaleButton<Label: View>: View {
    let action: () -> Void
    let label: Label

    @State private var isPressed = false

    init(action: @escaping () -> Void, @ViewBuilder label: () -> Label) {
        self.action = action
        self.label = label()
    }

    var body: some View {
        label
            .scaleEffect(isPressed ? 0.93 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.5), value: isPressed)
            .onTapGesture {
                withAnimation { isPressed = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    withAnimation { isPressed = false }
                    action()
                }
            }
    }
}
