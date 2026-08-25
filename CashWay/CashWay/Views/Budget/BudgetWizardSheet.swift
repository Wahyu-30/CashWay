import SwiftUI
import SwiftData

struct BudgetWizardSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss)      private var dismiss
    
    let month: Int
    let year: Int
    let income: Decimal
    let expenseData: [(category: Category, avgAmount: Decimal)]
    
    @State private var use503020 = true
    
    @Query(filter: #Predicate<Category> { $0.typeRaw == "expense" }) private var allExpenseCategories: [Category]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: CWSpacing.lg) {
                    
                    // Header
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Auto-Budget Wizard")
                            .font(.title2.bold())
                            .foregroundStyle(Color.cwTextPrimary)
                        Text("Buat budget bulanan secara otomatis berdasarkan pemasukan atau pola pengeluaran lamamu.")
                            .font(.caption)
                            .foregroundStyle(Color.cwTextSecondary)
                    }
                    .padding(.top, CWSpacing.md)
                    
                    // Toggle Method
                    Picker("Metode", selection: $use503020) {
                        Text("Aturan 50/30/20").tag(true)
                        Text("Analisis Historis").tag(false)
                    }
                    .pickerStyle(.segmented)
                    
                    if use503020 {
                        method503020View
                    } else {
                        methodHistoricalView
                    }
                    
                    Spacer(minLength: 40)
                    
                    Button {
                        applyBudget()
                    } label: {
                        Text("Terapkan Semua Budget")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.cwAccent, in: RoundedRectangle(cornerRadius: CWRadius.md))
                            .foregroundStyle(.white)
                    }
                    .buttonStyle(.plain)
                    
                }
                .padding(.horizontal, CWSpacing.md)
                .padding(.bottom, CWSpacing.xxl)
            }
            .background(Color.cwBackground)
            .navigationTitle("Wizard Budget")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Tutup") { dismiss() }.foregroundStyle(Color.cwTextSecondary)
                }
            }
        }
        .presentationDetents([.large])
        .preferredColorScheme(.dark)
    }
    
    // MARK: - 50/30/20 View
    private var method503020View: some View {
        VStack(alignment: .leading, spacing: CWSpacing.md) {
            Text("Pemasukan bulan ini: **\(CurrencyFormatter.format(income))**")
                .font(.subheadline)
                .foregroundStyle(Color.cwTextPrimary)
                .padding(.bottom, CWSpacing.xs)
            
            let needsLimit = income * 0.50
            let wantsLimit = income * 0.30
            let savingLimit = income * 0.20
            
            infoCard(title: "50% Kebutuhan Pokok", amount: needsLimit, desc: "Makan & Minum, Rumah & Tagihan, Transportasi, Kesehatan", color: .cwIncome)
            infoCard(title: "30% Keinginan (Wants)", amount: wantsLimit, desc: "Hiburan, Belanja, Langganan Digital", color: .cwWarning)
            infoCard(title: "20% Tabungan/Investasi", amount: savingLimit, desc: "Bisa ditambahkan ke Tabungan Goal", color: .cwAccent)
        }
    }
    
    private func infoCard(title: String, amount: Decimal, desc: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundStyle(Color.cwTextPrimary)
                Spacer()
                Text(CurrencyFormatter.format(amount))
                    .font(.subheadline.bold())
                    .foregroundStyle(color)
            }
            Text(desc)
                .font(.caption2)
                .foregroundStyle(Color.cwTextSecondary)
        }
        .padding(CWSpacing.md)
        .background(Color.cwSurface, in: RoundedRectangle(cornerRadius: CWRadius.sm))
        .overlay(RoundedRectangle(cornerRadius: CWRadius.sm).stroke(Color.cwBorder, lineWidth: 1))
    }
    
    // MARK: - Historical View
    private var methodHistoricalView: some View {
        VStack(alignment: .leading, spacing: CWSpacing.md) {
            if expenseData.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "tray")
                        .font(.largeTitle)
                        .foregroundStyle(Color.cwTextSecondary)
                    Text("Belum Ada Data Historis")
                        .font(.headline)
                    Text("Kamu harus mencatat pengeluaran setidaknya bulan lalu agar fitur ini bisa mempelajari kebiasaanmu.")
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Color.cwTextSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                Text("Rata-rata Pengeluaran Bulan Sebelumnya")
                    .font(.subheadline)
                    .foregroundStyle(Color.cwTextSecondary)
                
                ForEach(expenseData, id: \.category.id) { data in
                    HStack {
                        Image(systemName: data.category.icon)
                            .foregroundStyle(Color(hex: data.category.colorHex))
                            .frame(width: 24)
                        Text(data.category.name)
                            .font(.caption)
                        Spacer()
                        Text(CurrencyFormatter.format(data.avgAmount))
                            .font(.caption.bold())
                    }
                    .padding(CWSpacing.sm)
                    .background(Color.cwSurface, in: RoundedRectangle(cornerRadius: CWRadius.sm))
                }
            }
        }
    }
    
    // MARK: - Generate Logic
    private func applyBudget() {
        if use503020 {
            generate503020Budgets()
        } else {
            generateHistoricalBudgets()
        }
        dismiss()
    }
    
    private func generate503020Budgets() {
        guard income > 0 else { return }
        
        let needsLimit = income * 0.50
        let wantsLimit = income * 0.30
        
        let needCats = ["Makan & Minum", "Rumah & Tagihan", "Transportasi", "Kesehatan", "Pendidikan"]
        let wantCats = ["Hiburan", "Belanja", "Langganan Digital", "Perjalanan", "Perlengkapan Kerja"]
        
        // Find existing categories
        let nCats = allExpenseCategories.filter { needCats.contains($0.name) }
        let wCats = allExpenseCategories.filter { wantCats.contains($0.name) }
        
        if !nCats.isEmpty {
            let limitPerCat = needsLimit / Decimal(nCats.count)
            for cat in nCats { insertOrUpdate(category: cat, amount: limitPerCat) }
        }
        
        if !wCats.isEmpty {
            let limitPerCat = wantsLimit / Decimal(wCats.count)
            for cat in wCats { insertOrUpdate(category: cat, amount: limitPerCat) }
        }
        try? modelContext.save()
    }
    
    private func generateHistoricalBudgets() {
        for data in expenseData {
            // Buffer 10% lebih besar dari rata-rata agar tidak terlalu ketat
            let proposed = data.avgAmount * 1.10
            insertOrUpdate(category: data.category, amount: proposed)
        }
        try? modelContext.save()
    }
    
    private func insertOrUpdate(category: Category, amount: Decimal) {
        let descriptor = FetchDescriptor<Budget>()
        let existing = (try? modelContext.fetch(descriptor)) ?? []
        if let budget = existing.first(where: { $0.month == month && $0.year == year && $0.category?.id == category.id }) {
            budget.amount = amount
        } else {
            let budget = Budget(amount: amount, month: month, year: year, category: category)
            modelContext.insert(budget)
        }
    }
}
