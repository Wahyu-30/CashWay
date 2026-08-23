import SwiftUI
import SwiftData

// ============================================================
// MARK: - BudgetView
// Tampilan budget per kategori per bulan.
// Menampilkan progress bar dengan warna berdasarkan status.
// ============================================================

struct BudgetView: View {

    @Environment(\.modelContext) private var modelContext

    @Query(sort: \Budget.month) private var budgets:     [Budget]
    @Query                      private var categories:  [Category]

    @State private var selectedMonth: Int  = Calendar.current.component(.month, from: .now)
    @State private var selectedYear:  Int  = Calendar.current.component(.year,  from: .now)
    @State private var showAddBudget: Bool = false
    @State private var editingBudget: Budget? = nil

    private var monthBudgets: [Budget] {
        budgets.filter { $0.month == selectedMonth && $0.year == selectedYear }
    }

    private var totalBudget: Decimal   { monthBudgets.reduce(0) { $0 + $1.amount } }
    private var totalSpent:  Decimal   { monthBudgets.reduce(0) { $0 + $1.spent } }

    var body: some View {
        ScrollView {
            VStack(spacing: CWSpacing.md) {
                monthNavigator
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
            ForEach(monthBudgets) { budget in
                BudgetRowView(budget: budget)
                    .onTapGesture { editingBudget = budget }
                    .contextMenu {
                        Button("Edit") { editingBudget = budget }
                        Button("Hapus", role: .destructive) {
                            modelContext.delete(budget)
                            try? modelContext.save()
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

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss)      private var dismiss

    @Query private var allCategories: [Category]
    private var expenseCategories: [Category] {
        allCategories.filter { $0.type == .expense }
    }

    var editingBudget: Budget? = nil
    var month: Int = Calendar.current.component(.month, from: .now)
    var year:  Int = Calendar.current.component(.year,  from: .now)

    @State private var selectedCategory: Category? = nil
    @State private var amountText: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Kategori") {
                    Picker("Pilih kategori", selection: $selectedCategory) {
                        Text("Pilih...").tag(Optional<Category>(nil))
                        ForEach(expenseCategories) { cat in
                            Label(cat.name, systemImage: cat.icon).tag(Optional(cat))
                        }
                    }
                }
                Section("Batas Budget") {
                    HStack {
                        Text("Rp").foregroundStyle(Color.cwTextSecondary)
                        TextField("0", text: $amountText)
                            #if os(iOS)
                            .keyboardType(.numberPad)
                            #endif
                    }
                }
            }
            .scrollContentBackground(.hidden)
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
        .preferredColorScheme(.dark)
        .onAppear { loadEditingData() }
    }

    private var canSave: Bool {
        selectedCategory != nil && CurrencyFormatter.parse(amountText) > 0
    }

    private func save() {
        let amount = CurrencyFormatter.parse(amountText)
        if let existing = editingBudget {
            existing.amount   = amount
            existing.category = selectedCategory
        } else {
            let budget = Budget(
                amount:   amount,
                month:    month,
                year:     year,
                category: selectedCategory
            )
            modelContext.insert(budget)
        }
        try? modelContext.save()
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
        .modelContainer(for: [Transaction.self, Category.self, Wallet.self, Budget.self], inMemory: true)
        .preferredColorScheme(.dark)
}
