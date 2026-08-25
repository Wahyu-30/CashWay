import SwiftUI
import SwiftData

struct AddDepositSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss)      private var dismiss
    
    let goal: SavingsGoal
    @State private var amountText: String = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: CWSpacing.lg) {
                
                VStack(spacing: 8) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(hex: goal.colorHex).opacity(0.15))
                            .frame(width: 56, height: 56)
                        Image(systemName: goal.icon)
                            .font(.title2.bold())
                            .foregroundStyle(Color(hex: goal.colorHex))
                    }
                    Text(goal.name)
                        .font(.title3.bold())
                        .foregroundStyle(Color.cwTextPrimary)
                    Text("Sisa target: \(CurrencyFormatter.format(goal.targetAmount - goal.currentAmount))")
                        .font(.caption)
                        .foregroundStyle(Color.cwTextSecondary)
                }
                .padding(.top, CWSpacing.xl)
                
                VStack(alignment: .leading, spacing: CWSpacing.sm) {
                    Text("Nominal Setoran")
                        .font(.subheadline)
                        .foregroundStyle(Color.cwTextSecondary)
                    HStack {
                        Text("Rp").font(.title2).foregroundStyle(Color.cwTextSecondary)
                        TextField("0", text: $amountText)
                            .textFieldStyle(.plain)
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .onChange(of: amountText) {
                                amountText = amountText.filter { $0.isNumber }
                            }
                    }
                    .padding(CWSpacing.md)
                    .background(Color.cwSurface, in: RoundedRectangle(cornerRadius: CWRadius.md))
                    .overlay(RoundedRectangle(cornerRadius: CWRadius.md).stroke(Color.cwBorder, lineWidth: 1))
                    
                    // Quick add buttons
                    HStack {
                        quickAddButton(amount: 50000)
                        quickAddButton(amount: 100000)
                        quickAddButton(amount: 500000)
                    }
                    .padding(.top, CWSpacing.xs)
                }
                
                Spacer()
            }
            .padding(.horizontal, CWSpacing.md)
            .background(Color.cwBackground)
            .navigationTitle("Setor Tabungan")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Batal") { dismiss() }.foregroundStyle(Color.cwTextSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Simpan") { save() }
                        .bold()
                        .foregroundStyle(canSave ? Color.cwAccent : Color.cwPlaceholder)
                        .disabled(!canSave)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .preferredColorScheme(.dark)
    }
    
    private func quickAddButton(amount: Decimal) -> some View {
        Button {
            let current = CurrencyFormatter.parse(amountText)
            amountText = "\(current + amount)"
        } label: {
            Text("+\(CurrencyFormatter.formatCompact(amount))")
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.cwSurfaceElevated, in: RoundedRectangle(cornerRadius: CWRadius.sm))
                .foregroundStyle(Color.cwTextSecondary)
        }
        .buttonStyle(.plain)
    }
    
    private var canSave: Bool {
        CurrencyFormatter.parse(amountText) > 0
    }
    
    private func save() {
        let amount = CurrencyFormatter.parse(amountText)
        
        // Tambahkan saldo ke goal
        goal.currentAmount += amount
        
        // Otomatis catat sebagai transaksi pengeluaran (menabung)
        // Cari wallet default
        let descriptor = FetchDescriptor<Wallet>()
        let wallets = (try? modelContext.fetch(descriptor)) ?? []
        let defaultWallet = wallets.first(where: { $0.isDefault }) ?? wallets.first
        
        // Cari kategori tabungan / lainnya
        let catDesc = FetchDescriptor<Category>()
        let cats = (try? modelContext.fetch(catDesc)) ?? []
        let cat = cats.first(where: { $0.name == "Investasi" || $0.name == "Lainnya" })
        
        let tx = Transaction(
            type: .expense,
            amount: amount,
            date: .now,
            note: "Setor Tabungan: \(goal.name)",
            wallet: defaultWallet,
            category: cat
        )
        
        modelContext.insert(tx)
        try? modelContext.save()
        dismiss()
    }
}
