import SwiftUI
import Charts

// ============================================================
// MARK: - ReportsView
// Laporan keuangan bulanan dan tahunan.
// ============================================================

struct ReportsView: View {

    @EnvironmentObject private var dataStore: DataStore

    @State private var selectedMonth: Int = Calendar.current.component(.month, from: .now)
    @State private var selectedYear:  Int = Calendar.current.component(.year,  from: .now)

    private var monthTx: [Transaction] {
        let cal = Calendar.current
        return dataStore.transactions.filter {
            cal.component(.month, from: $0.date) == selectedMonth &&
            cal.component(.year,  from: $0.date) == selectedYear
        }
    }

    private var expenseTx: [Transaction] { monthTx.filter { $0.type == .expense } }
    private var incomeTx:  [Transaction] { monthTx.filter { $0.type == .income } }

    private var totalExpense: Decimal { expenseTx.reduce(0) { $0 + $1.amount } }
    private var totalIncome:  Decimal { incomeTx.reduce(0)  { $0 + $1.amount } }
    private var netSaving:    Decimal { totalIncome - totalExpense }

    @State private var chartType: Transaction.TransactionType = .expense

    // Expense by category untuk pie chart
    private var expenseByCategory: [(name: String, amount: Double, colorHex: String)] {
        Dictionary(grouping: expenseTx) { $0.category?.name ?? "Lainnya" }
            .map { key, txs in (
                name:     key,
                amount:   NSDecimalNumber(decimal: txs.reduce(0) { $0 + $1.amount }).doubleValue,
                colorHex: txs.first?.category?.colorHex ?? "#8B8FA8"
            )}
            .sorted { $0.amount > $1.amount }
    }
    
    // Income by category untuk pie chart
    private var incomeByCategory: [(name: String, amount: Double, colorHex: String)] {
        Dictionary(grouping: incomeTx) { $0.category?.name ?? "Lainnya" }
            .map { key, txs in (
                name:     key,
                amount:   NSDecimalNumber(decimal: txs.reduce(0) { $0 + $1.amount }).doubleValue,
                colorHex: txs.first?.category?.colorHex ?? "#8B8FA8"
            )}
            .sorted { $0.amount > $1.amount }
    }
    
    private var currentChartData: [(name: String, amount: Double, colorHex: String)] {
        chartType == .expense ? expenseByCategory : incomeByCategory
    }
    
    private var currentTotal: Decimal {
        chartType == .expense ? totalExpense : totalIncome
    }

    var body: some View {
        ScrollView {
            VStack(spacing: CWSpacing.lg) {
                SlideInCard(index: 0) { monthNavigator }
                SlideInCard(index: 1) { summaryCards }
                SlideInCard(index: 2) { categoryChart }
                SlideInCard(index: 3) { categoryTable }
            }
            .padding(CWSpacing.md)
        }
        .background(Color.cwBackground)
        .navigationTitle("Laporan")
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

    // MARK: - Summary Cards
    private var summaryCards: some View {
        VStack(spacing: CWSpacing.sm) {
            HStack(spacing: CWSpacing.sm) {
                summaryCard(label: "Total Masuk",   amount: totalIncome,  color: .cwIncome)
                summaryCard(label: "Total Keluar",  amount: totalExpense, color: .cwExpense)
            }
            summaryCard(
                label:  netSaving >= 0 ? "💰 Tabungan Bulan Ini" : "🔴 Defisit Bulan Ini",
                amount: abs(netSaving),
                color:  netSaving >= 0 ? .cwIncome : .cwExpense,
                fullWidth: true
            )
        }
    }

    private func summaryCard(label: String, amount: Decimal, color: Color, fullWidth: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: CWSpacing.xs) {
            Text(label).font(.caption).foregroundStyle(Color.cwTextSecondary)
            Text(CurrencyFormatter.format(amount))
                .font(.subheadline.bold()).foregroundStyle(color).monospacedDigit()
        }
        .frame(maxWidth: fullWidth ? .infinity : nil, alignment: .leading)
        .padding(CWSpacing.md)
        .background(Color.cwSurface, in: RoundedRectangle(cornerRadius: CWRadius.md))
        .frame(maxWidth: fullWidth ? .infinity : nil)
    }

    // MARK: - Pie / Donut Chart
    private var categoryChart: some View {
        VStack(alignment: .leading, spacing: CWSpacing.sm) {
            HStack {
                Text("Distribusi Kategori")
                    .font(.subheadline.weight(.semibold)).foregroundStyle(Color.cwTextSecondary)
                Spacer()
                Picker("", selection: $chartType) {
                    Text("Pengeluaran").tag(Transaction.TransactionType.expense)
                    Text("Pemasukan").tag(Transaction.TransactionType.income)
                }
                .pickerStyle(.segmented)
                .frame(width: 200)
            }

            VStack {
                if !currentChartData.isEmpty {
                    Chart(currentChartData, id: \.name) { item in
                        SectorMark(
                            angle: .value("Jumlah", item.amount),
                            innerRadius: .ratio(0.55),
                            angularInset: 2
                        )
                        .foregroundStyle(Color(hex: item.colorHex))
                        .cornerRadius(3)
                    }
                    .frame(height: 200)
                } else {
                    // Empty state for pie chart
                    ZStack {
                        Circle()
                            .stroke(Color.cwBorder, lineWidth: 40)
                            .frame(width: 150, height: 150)
                        VStack {
                            Image(systemName: "chart.pie.fill")
                                .font(.title)
                                .foregroundStyle(Color.cwTextSecondary)
                            Text("Data Kosong")
                                .font(.caption)
                                .foregroundStyle(Color.cwTextSecondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
                }
            }
            .padding(CWSpacing.sm)
            .background(Color.cwSurface, in: RoundedRectangle(cornerRadius: CWRadius.md))
        }
    }

    // MARK: - Category Breakdown Table
    private var categoryTable: some View {
        VStack(alignment: .leading, spacing: CWSpacing.sm) {
            Text("Rincian per Kategori (\(chartType == .expense ? "Keluar" : "Masuk"))")
                .font(.subheadline.weight(.semibold)).foregroundStyle(Color.cwTextSecondary)

            if currentChartData.isEmpty {
                Text(chartType == .expense ? "Belum ada pengeluaran bulan ini" : "Belum ada pemasukan bulan ini")
                    .font(.caption).foregroundStyle(Color.cwTextSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(CWSpacing.lg)
                    .background(Color.cwSurface, in: RoundedRectangle(cornerRadius: CWRadius.md))
            } else {
                VStack(spacing: 1) {
                    ForEach(currentChartData, id: \.name) { item in
                        HStack {
                            Circle().fill(Color(hex: item.colorHex)).frame(width: 10, height: 10)
                            Text(item.name).font(.subheadline).foregroundStyle(Color.cwTextPrimary)
                            Spacer()
                            Text(CurrencyFormatter.format(Decimal(item.amount)))
                                .font(.footnote.bold())
                                .foregroundStyle(chartType == .expense ? Color.cwExpense : Color.cwIncome)
                                .monospacedDigit()
                            Text(currentTotal > 0 ? "\(Int(item.amount / NSDecimalNumber(decimal: currentTotal).doubleValue * 100))%" : "")
                                .font(.caption).foregroundStyle(Color.cwTextSecondary).frame(width: 35, alignment: .trailing)
                        }
                        .padding(.horizontal, CWSpacing.md)
                        .padding(.vertical, CWSpacing.sm)
                        if item.name != currentChartData.last?.name {
                            Divider().background(Color.cwBorder).padding(.leading, CWSpacing.md)
                        }
                    }
                }
                .background(Color.cwSurface, in: RoundedRectangle(cornerRadius: CWRadius.md))
            }
        }
    }

    // MARK: - Helpers
    private var monthTitle: String {
        let f = DateFormatter(); f.locale = Locale(identifier: "id_ID"); f.dateFormat = "MMMM yyyy"
        return f.string(from: Calendar.current.date(from: DateComponents(year: selectedYear, month: selectedMonth)) ?? .now)
    }

    private func prevMonth() {
        if selectedMonth == 1 { selectedMonth = 12; selectedYear -= 1 } else { selectedMonth -= 1 }
    }

    private func nextMonth() {
        if selectedMonth == 12 { selectedMonth = 1; selectedYear += 1 } else { selectedMonth += 1 }
    }
}

#Preview {
    NavigationStack { ReportsView() }
        .environmentObject(DataStore())
        .preferredColorScheme(.dark)
}
