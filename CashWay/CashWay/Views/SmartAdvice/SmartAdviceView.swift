import SwiftUI

// ============================================================
// MARK: - SmartAdviceView
// Halaman yang menampilkan semua saran keuangan dari SmartAdviceEngine.
// Bisa dibuka dari banner di Dashboard atau tab sendiri.
// ============================================================

struct SmartAdviceView: View {

    let advices: [SmartAdvice]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: CWSpacing.md) {
                    if advices.isEmpty {
                        emptyState
                    } else {
                        header
                        ForEach(advices) { advice in
                            AdviceCard(advice: advice)
                        }
                    }
                }
                .padding(CWSpacing.md)
            }
            .background(Color.cwBackground)
            .navigationTitle("Saran Keuangan")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Tutup") { dismiss() }.foregroundStyle(Color.cwAccent)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: CWSpacing.xs) {
            Text("Analisis bulan ini")
                .font(.caption).foregroundStyle(Color.cwTextSecondary)
            Text("\(advices.filter { $0.priority == .high }.count) peringatan · \(advices.count) saran total")
                .font(.footnote.weight(.semibold)).foregroundStyle(Color.cwTextPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var emptyState: some View {
        VStack(spacing: CWSpacing.md) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 60)).foregroundStyle(Color.cwAccent)
            Text("Keuangan Aman! 🎉")
                .font(.title2.bold()).foregroundStyle(Color.cwTextPrimary)
            Text("Tidak ada peringatan bulan ini.\nTerus pertahankan!")
                .font(.body).foregroundStyle(Color.cwTextSecondary).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity).padding(CWSpacing.xxl)
    }
}

// ============================================================
// MARK: - AdviceCard
// Satu kartu saran dengan icon, judul, pesan, dan tombol aksi.
// ============================================================

struct AdviceCard: View {
    let advice: SmartAdvice

    var body: some View {
        VStack(alignment: .leading, spacing: CWSpacing.sm) {
            // Header
            HStack(alignment: .top, spacing: CWSpacing.sm) {
                Image(systemName: advice.type.icon)
                    .foregroundStyle(Color(hex: advice.type.accentColorHex))
                    .font(.title3)
                    .frame(width: 36, height: 36)
                    .background(
                        Color(hex: advice.type.accentColorHex).opacity(0.2),
                        in: RoundedRectangle(cornerRadius: CWRadius.sm)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    // Priority badge
                    if advice.priority == .high {
                        Text("PRIORITAS TINGGI")
                            .font(.system(size: 9).bold())
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Color(hex: "#FF6B6B").opacity(0.2), in: Capsule())
                            .foregroundStyle(Color(hex: "#FF6B6B"))
                    }
                    Text(advice.title)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Color.cwTextPrimary)
                }
            }

            // Message
            Text(advice.message)
                .font(.caption)
                .foregroundStyle(Color.cwTextSecondary)
                .fixedSize(horizontal: false, vertical: true)

            // Action button
            if let action = advice.action {
                Button {
                    // TODO: navigate to relevant screen
                } label: {
                    Text(action)
                        .font(.caption.bold())
                        .foregroundStyle(Color(hex: advice.type.accentColorHex))
                        .padding(.horizontal, CWSpacing.sm)
                        .padding(.vertical, CWSpacing.xs)
                        .background(
                            Color(hex: advice.type.accentColorHex).opacity(0.15),
                            in: RoundedRectangle(cornerRadius: CWRadius.sm)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(CWSpacing.md)
        .background(Color(hex: advice.type.backgroundColorHex), in: RoundedRectangle(cornerRadius: CWRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: CWRadius.md)
                .stroke(Color(hex: advice.type.accentColorHex).opacity(0.3), lineWidth: 1)
        )
    }
}

#Preview {
    SmartAdviceView(advices: [
        SmartAdvice(
            type: .overBudget, priority: .high,
            title: "⚠️ Budget Makan Terlampaui",
            message: "Pengeluaran Makan & Minum sudah melebihi budget 25%. Tips: Coba meal prep 2-3x seminggu.",
            action: "Lihat transaksi", category: "Makan & Minum"
        ),
        SmartAdvice(
            type: .tip, priority: .medium,
            title: "💡 Optimasi Freelance",
            message: "Kamu dapat Rp 2.500.000 dari freelance. Saran: 50% tabungan, 30% kebutuhan, 20% investasi.",
            action: nil, category: nil
        ),
        SmartAdvice(
            type: .positive, priority: .low,
            title: "✅ Keuangan Sehat!",
            message: "Pengeluaran baru 45% dari gaji. Kamu bisa sisihkan lebih ke tabungan.",
            action: "Tambah tabungan", category: nil
        ),
    ])
}
