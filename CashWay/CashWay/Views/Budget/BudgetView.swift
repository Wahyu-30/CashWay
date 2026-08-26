import SwiftUI

// ============================================================
// MARK: - BudgetView
// Tampilan budget per kategori per bulan.
// Menampilkan progress bar dengan warna berdasarkan status.
// ============================================================

struct BudgetView: View {

    @EnvironmentObject private var dataStore: DataStore

    @State private var selectedMonth: Int  = Calendar.current.component(.month, from: .now)
    @State private var selectedYear:  Int  = Calendar.current.component(.year,  from: .now)
    @State private var showAddBudget: Bool = false
    @State private var showWizard: Bool = false
    @State private var editingBudget: Budget? = nil

    private var monthBudgets: [Budget] {
        dataStore.budgets.filter { $0.month == selectedMonth && $0.year == selectedYear }
    }

    private var totalBudget: Decimal   { monthBudgets.reduce(0) { $0 + $1.amount } }
    private var totalSpent:  Decimal   { monthBudgets.reduce(0) { $0 + $1.spent } }

    var body: some View {
        ScrollView {
            VStack(spacing: CWSpacing.md) {
                monthNavigator
                
                Button { showWizard = true } label: {
                    HStack {
                        Image(systemName: "wand.and.stars")
                        Text("Auto-Budget Wizard")
                    }
                    .font(.caption.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(LinearGradient(colors: [Color.cwAccent, Color(hex: "#9019e6")], startPoint: .leading, endPoint: .trailing), in: RoundedRectangle(cornerRadius: CWRadius.md))
                    .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
                
                overallSummary
                if monthBudgets.isEmpty { emptyState } else { budgetList }
            }
            .padding(CWSpacing.md)
        }
        .background(Color.cwBackground)
        .navigationTitle("Budget")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showAddBudget = true } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(Color.cwAccent).font(.title3)
                }
            }
        }
        .sheet(isPresented: $showAddBudget) { AddBudgetSheet(month: selectedMonth, year: selectedYear) }
        .sheet(item: $editingBudget) { budget in AddBudgetSheet(editingBudget: budget) }
        .sheet(isPresented: $showWizard) {
            BudgetWizardSheet(
                month: selectedMonth,
                year: selectedYear,
                income: calculateIncome(),
                expenseData: calculateHistoricalData()
            )
        }
    }
    
    // MARK: - Helper for Wizard
    private func calculateIncome() -> Decimal {
        let cal = Calendar.current
        let currentTx = dataStore.transactions.filter {
            let m = cal.component(.month, from: $0.date)
            let y = cal.component(.year, from: $0.date)
            return m == selectedMonth && y == selectedYear && $0.type == .income
        }
        return currentTx.reduce(0) { $0 + $1.amount }
    }
    
    private func calculateHistoricalData() -> [(category: Category, avgAmount: Decimal)] {
        let cal = Calendar.current
        
        // Cari transaksi 3 bulan terakhir sebelum bulan yang dipilih
        guard let currentDate = cal.date(from: DateComponents(year: selectedYear, month: selectedMonth)),
              let pastDate = cal.date(byAdding: .month, value: -3, to: currentDate) else { return [] }
        
        let pastTx = dataStore.transactions.filter {
            $0.type == .expense && $0.date >= pastDate && $0.date < currentDate && $0.category != nil
        }
        
        var dict: [String: (cat: Category, sum: Decimal)] = [:]
        for tx in pastTx {
            if let cat = tx.category {
                let current = dict[cat.id]?.sum ?? 0
                dict[cat.id] = (cat, current + tx.amount)
            }
        }
        
        return dict.values.map {
            // Dibagi 3 untuk rata-rata 3 bulan
            (category: $0.cat, avgAmount: $0.sum / 3)
        }.sorted { $0.avgAmount > $1.avgAmount }
    }

    // MARK: - Month Navigator
    private var monthNavigator: some View {
        HStack {
            Button { prevMonth() } label: {
                Image(systemName: "chevron.left")
                    .font(.title3.bold())
                    .foregroundStyle(Color.cwTextSecondary)
                    .padding(.horizontal, CWSpacing.sm)
            }
            .buttonStyle(.plain)

            Spacer()
            
            Text(monthTitle)
                .font(.title3.weight(.bold))
                .foregroundStyle(Color.cwTextPrimary)
                
            Spacer()
            
            Button { nextMonth() } label: {
                Image(systemName: "chevron.right")
                    .font(.title3.bold())
                    .foregroundStyle(Color.cwTextSecondary)
                    .padding(.horizontal, CWSpacing.sm)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, CWSpacing.sm)
    }

    // MARK: - Overall Summary
    private var overallSummary: some View {
        let overallPct = totalBudget > 0 ? Double(truncating: (totalSpent / totalBudget) as NSDecimalNumber) : 0
        return VStack(spacing: CWSpacing.sm) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Total Budget").font(.caption).foregroundStyle(Color.cwTextSecondary)
                    Text(CurrencyFormatter.format(totalBudget))
                        .font(.title3.bold()).foregroundStyle(Color.cwTextPrimary).monospacedDigit()
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text("Terpakai").font(.caption).foregroundStyle(Color.cwTextSecondary)
                    Text(CurrencyFormatter.format(totalSpent))
                        .font(.title3.bold())
                        .foregroundStyle(overallPct > 1 ? Color.cwExpense : Color.cwAccent)
                        .monospacedDigit()
                }
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4).fill(Color.cwBorder).frame(height: 8)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(progressColor(pct: overallPct))
                        .frame(width: geo.size.width * min(CGFloat(overallPct), 1.0), height: 8)
                }
            }
            .frame(height: 8)
        }
        .padding(CWSpacing.md)
        .background(Color.cwSurface, in: RoundedRectangle(cornerRadius: CWRadius.md))
    }

    // MARK: - Budget List
    private var budgetList: some View {
        VStack(spacing: CWSpacing.sm) {
            ForEach(Array(monthBudgets.enumerated()), id: \.element.id) { index, budget in
                SlideInCard(index: index) {
                    BudgetRowView(budget: budget)
                        .onTapGesture { editingBudget = budget }
                        .contextMenu {
                            Button("Edit") { editingBudget = budget }
                            Button("Hapus", role: .destructive) {
                                dataStore.deleteBudget(budget)
                            }
                        }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: CWSpacing.md) {
            Image(systemName: "target").font(.largeTitle).foregroundStyle(Color.cwTextSecondary)
            Text("Belum ada budget").font(.headline).foregroundStyle(Color.cwTextPrimary)
            Text("Ketuk + untuk set budget per kategori").font(.caption).foregroundStyle(Color.cwTextSecondary)
        }
        .frame(maxWidth: .infinity).padding(CWSpacing.xxl)
    }

    // MARK: - Helpers
    private var monthTitle: String {
        let f = DateFormatter(); f.locale = Locale(identifier: "id_ID"); f.dateFormat = "MMMM yyyy"
        return f.string(from: Calendar.current.date(from: DateComponents(year: selectedYear, month: selectedMonth)) ?? .now)
    }

    private func prevMonth() {
        if selectedMonth == 1 { selectedMonth = 12; selectedYear -= 1 }
        else { selectedMonth -= 1 }
    }

    private func nextMonth() {
        if selectedMonth == 12 { selectedMonth = 1; selectedYear += 1 }
        else { selectedMonth += 1 }
    }

    private func progressColor(pct: Double) -> Color {
        pct > 1.0 ? .cwExpense : pct >= 0.8 ? .cwWarning : .cwAccent
    }
}

// ============================================================
// MARK: - BudgetRowView
// Satu baris budget dengan progress bar.
// ============================================================

struct BudgetRowView: View {
    let budget: Budget

    var body: some View {
        VStack(spacing: CWSpacing.sm) {
            HStack {
                // Icon + nama kategori
                HStack(spacing: CWSpacing.sm) {
                    Image(systemName: budget.category?.icon ?? "questionmark")
                        .foregroundStyle(Color(hex: budget.category?.colorHex ?? "#8B8FA8"))
                        .font(.body)
                        .frame(width: 32, height: 32)
                        .background(
                            Color(hex: budget.category?.colorHex ?? "#8B8FA8").opacity(0.15),
                            in: RoundedRectangle(cornerRadius: CWRadius.sm)
                        )
                    Text(budget.category?.name ?? "Kategori")
                        .font(.subheadline.weight(.semibold)).foregroundStyle(Color.cwTextPrimary)
                }
                Spacer()
                // Status badge
                statusBadge
            }

            // Amount info
            HStack {
                Text(CurrencyFormatter.format(budget.spent))
                    .font(.footnote.bold())
                    .foregroundStyle(Color(hex: budget.status.colorHex))
                    .monospacedDigit()
                Text("dari \(CurrencyFormatter.format(budget.amount))")
                    .font(.caption).foregroundStyle(Color.cwTextSecondary)
                    .monospacedDigit()
                Spacer()
                Text("\(Int(min(budget.percentage * 100, 999)))%")
                    .font(.footnote.bold())
                    .foregroundStyle(Color(hex: budget.status.colorHex))
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4).fill(Color.cwBorder).frame(height: 6)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(hex: budget.status.colorHex))
                        .frame(width: geo.size.width * CGFloat(min(budget.percentage, 1.0)), height: 6)
                }
            }
            .frame(height: 6)
        }
        .padding(CWSpacing.md)
        .background(Color.cwSurface, in: RoundedRectangle(cornerRadius: CWRadius.md))
    }

    private var statusBadge: some View {
        HStack(spacing: 3) {
            Image(systemName: budget.status.icon).font(.system(size: 9))
            Text(budget.status.label).font(.system(size: 9).bold())
        }
        .padding(.horizontal, 7).padding(.vertical, 3)
        .background(Color(hex: budget.status.colorHex).opacity(0.2), in: Capsule())
        .foregroundStyle(Color(hex: budget.status.colorHex))
    }
}

// ============================================================
// MARK: - AddBudgetSheet
// Sheet untuk menambah atau mengedit budget.
// ============================================================

struct AddBudgetSheet: View {

    @EnvironmentObject private var dataStore: DataStore
    @Environment(\.dismiss)      private var dismiss

    private var expenseCategories: [Category] {
        dataStore.categories.filter { $0.type == .expense }
    }

    var editingBudget: Budget? = nil
    var month: Int = Calendar.current.component(.month, from: .now)
    var year:  Int = Calendar.current.component(.year,  from: .now)

    @State private var selectedCategory: Category? = nil
    @State private var amountText: String = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: CWSpacing.lg) {

                    // MARK: Judul icon
                    VStack(spacing: CWSpacing.xs) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(LinearGradient(
                                    colors: [Color.cwAccent, Color(hex: "#9019e6")],
                                    startPoint: .topLeading, endPoint: .bottomTrailing
                                ))
                                .frame(width: 56, height: 56)
                            Image(systemName: "target")
                                .font(.title2.bold())
                                .foregroundStyle(.white)
                        }
                        Text(editingBudget == nil ? "Set Batas Budget" : "Edit Budget")
                            .font(.title3.bold())
                            .foregroundStyle(Color.cwTextPrimary)
                        Text("Tentukan batas pengeluaran per kategori")
                            .font(.caption)
                            .foregroundStyle(Color.cwTextSecondary)
                    }
                    .padding(.top, CWSpacing.md)

                    // MARK: Pilih Kategori
                    VStack(alignment: .leading, spacing: CWSpacing.sm) {
                        Text("Kategori Pengeluaran")
                            .font(.subheadline)
                            .foregroundStyle(Color.cwTextSecondary)

                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: CWSpacing.sm) {
                            ForEach(expenseCategories) { cat in
                                let isSelected = selectedCategory?.id == cat.id
                                Button {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                        selectedCategory = isSelected ? nil : cat
                                    }
                                } label: {
                                    VStack(spacing: 6) {
                                        Image(systemName: cat.icon)
                                            .font(.title3)
                                            .foregroundStyle(isSelected ? .white : Color(hex: cat.colorHex))
                                            .frame(width: 44, height: 44)
                                            .background(
                                                isSelected ? Color(hex: cat.colorHex) : Color(hex: cat.colorHex).opacity(0.15),
                                                in: RoundedRectangle(cornerRadius: CWRadius.sm)
                                            )
                                            .overlay(
                                                RoundedRectangle(cornerRadius: CWRadius.sm)
                                                    .stroke(isSelected ? Color(hex: cat.colorHex) : Color.clear, lineWidth: 1.5)
                                            )
                                            .shadow(color: isSelected ? Color(hex: cat.colorHex).opacity(0.4) : .clear, radius: 6, y: 2)
                                        Text(cat.name)
                                            .font(.caption)
                                            .foregroundStyle(isSelected ? Color.cwTextPrimary : Color.cwTextSecondary)
                                            .lineLimit(2)
                                            .multilineTextAlignment(.center)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    Divider().background(Color.cwBorder)

                    // MARK: Batas Budget
                    VStack(alignment: .leading, spacing: CWSpacing.sm) {
                        Text("Batas Budget")
                            .font(.subheadline)
                            .foregroundStyle(Color.cwTextSecondary)

                        HStack {
                            Text("Rp")
                                .font(.title2)
                                .foregroundStyle(Color.cwTextSecondary)
                            TextField("0", text: $amountText)
                                .textFieldStyle(.plain)
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundStyle(Color.cwTextPrimary)
                                #if os(iOS)
                                .keyboardType(.numberPad)
                                #endif
                                .monospacedDigit()
                                .onChange(of: amountText) {
                                    let digits = amountText.filter { $0.isNumber }
                                    amountText = digits
                                }
                        }
                        .padding(CWSpacing.md)
                        .background(Color.cwSurface, in: RoundedRectangle(cornerRadius: CWRadius.md))
                        .overlay(
                            RoundedRectangle(cornerRadius: CWRadius.md)
                                .stroke(amountText.isEmpty ? Color.cwBorder : Color.cwAccent.opacity(0.5), lineWidth: 1)
                        )
                        .shadow(color: amountText.isEmpty ? .clear : Color.cwAccent.opacity(0.12), radius: 8, y: 4)

                        if let cat = selectedCategory, !amountText.isEmpty,
                           let amount = Double(amountText.filter { $0.isNumber }), amount > 0 {
                            HStack(spacing: 6) {
                                Image(systemName: cat.icon)
                                    .font(.caption)
                                    .foregroundStyle(Color(hex: cat.colorHex))
                                Text("\(cat.name) dibatasi \(CurrencyFormatter.format(Decimal(amount))) / bulan")
                                    .font(.caption)
                                    .foregroundStyle(Color.cwTextSecondary)
                            }
                            .padding(.horizontal, CWSpacing.xs)
                        }
                    }
                }
                .padding(.horizontal, CWSpacing.md)
                .padding(.bottom, CWSpacing.xxl)
            }
            .background(Color.cwBackground)
            .navigationTitle(editingBudget == nil ? "Tambah Budget" : "Edit Budget")
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
        .presentationDetents([.large])
        .preferredColorScheme(.dark)
        .onAppear { loadEditingData() }
    }

    private var canSave: Bool {
        selectedCategory != nil && CurrencyFormatter.parse(amountText) > 0
    }

    private func save() {
        let amount = CurrencyFormatter.parse(amountText)
        if var existing = editingBudget {
            existing.amount   = amount
            existing.category = selectedCategory
            dataStore.addBudget(existing)
        } else {
            let budget = Budget(
                amount:   amount,
                month:    month,
                year:     year,
                category: selectedCategory
            )
            dataStore.addBudget(budget)
        }
        dismiss()
    }

    private func loadEditingData() {
        if let b = editingBudget {
            selectedCategory = b.category
            amountText       = String(describing: b.amount)
        }
    }
}

#Preview {
    NavigationStack { BudgetView() }
        .environmentObject(DataStore())
        .preferredColorScheme(.dark)
}
