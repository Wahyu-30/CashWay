import SwiftUI
import Charts

// ============================================================
// MARK: - BudgetTableRow
// Data model untuk satu baris di tabel anggaran laporan.
// ============================================================

struct BudgetTableRow: Identifiable {
    let id: String
    let categoryName: String
    let colorHex: String
    let budgeted: Decimal?      // nil = tidak ada anggaran yang diset
    let spent: Decimal

    var progress: Double {
        guard let b = budgeted, b > 0 else { return spent > 0 ? 1.2 : 0.0 }
        return NSDecimalNumber(decimal: spent / b).doubleValue
    }

    var percentage: Double { progress * 100 }

    var isOverBudget: Bool {
        guard let b = budgeted else { return false }
        return spent > b
    }

    var isNearLimit: Bool {
        guard !isOverBudget, budgeted != nil else { return false }
        return progress >= 0.8
    }

    var statusColor: Color {
        if isOverBudget  { return Color(hex: "#FF6B6B") }
        if isNearLimit   { return Color(hex: "#F4A261") }
        return Color(hex: "#1a9b9b")
    }
}

// ============================================================
// MARK: - ReportsView
// Laporan keuangan bulanan dengan tabel anggaran bergaya
// dashboard profesional (mirip spreadsheet Money Management).
// ============================================================

struct ReportsView: View {

    @EnvironmentObject private var dataStore: DataStore

    @State private var selectedMonth: Int = Calendar.current.component(.month, from: .now)
    @State private var selectedYear:  Int = Calendar.current.component(.year,  from: .now)
    @State private var pdfURL: URL?
    @State private var showShareSheet = false
    @State private var isGeneratingPDF = false

    // MARK: - Computed: Transactions

    private var monthTx: [Transaction] {
        let cal = Calendar.current
        return dataStore.transactions.filter {
            cal.component(.month, from: $0.date) == selectedMonth &&
            cal.component(.year,  from: $0.date) == selectedYear
        }
    }
    private var expenseTx: [Transaction] { monthTx.filter { $0.type == .expense } }
    private var incomeTx:  [Transaction] { monthTx.filter { $0.type == .income  } }

    private var totalExpense: Decimal { expenseTx.reduce(0) { $0 + $1.amount } }
    private var totalIncome:  Decimal { incomeTx.reduce(0)  { $0 + $1.amount } }
    private var netSaving:    Decimal { totalIncome - totalExpense }

    // MARK: - Computed: Wallet Total Balance
    private var totalWalletBalance: Decimal {
        let initialTotal = dataStore.wallets.reduce(Decimal(0)) { $0 + $1.initialBalance }
        let allIncome    = dataStore.transactions.filter { $0.type == .income  }.reduce(Decimal(0)) { $0 + $1.amount }
        let allExpense   = dataStore.transactions.filter { $0.type == .expense }.reduce(Decimal(0)) { $0 + $1.amount }
        return initialTotal + allIncome - allExpense
    }

    // MARK: - Computed: Budget Table Rows
    private var budgetTableRows: [BudgetTableRow] {
        let monthBudgets = dataStore.budgets.filter {
            $0.month == selectedMonth && $0.year == selectedYear
        }

        // Hitung pengeluaran per kategori bulan ini
        var spendingMap: [String: (name: String, colorHex: String, amount: Decimal)] = [:]
        for tx in expenseTx {
            let catId    = tx.category?.id       ?? "other"
            let catName  = tx.category?.name     ?? "Lainnya"
            let catColor = tx.category?.colorHex ?? "#8B8FA8"
            if let existing = spendingMap[catId] {
                spendingMap[catId] = (name: catName, colorHex: catColor, amount: existing.amount + tx.amount)
            } else {
                spendingMap[catId] = (name: catName, colorHex: catColor, amount: tx.amount)
            }
        }

        var rows: [BudgetTableRow] = []
        var handled: Set<String> = []

        // Pertama: kategori yang punya anggaran
        for budget in monthBudgets {
            let catId  = budget.category?.id ?? ""
            handled.insert(catId)
            let spending = spendingMap[catId]?.amount ?? 0
            rows.append(BudgetTableRow(
                id:           catId.isEmpty ? UUID().uuidString : catId,
                categoryName: budget.category?.name     ?? "Lainnya",
                colorHex:     budget.category?.colorHex ?? "#8B8FA8",
                budgeted:     budget.amount,
                spent:        spending
            ))
        }

        // Kedua: kategori yang ada transaksinya tapi tidak punya anggaran
        for (catId, info) in spendingMap where !handled.contains(catId) {
            rows.append(BudgetTableRow(
                id:           catId,
                categoryName: info.name,
                colorHex:     info.colorHex,
                budgeted:     nil,
                spent:        info.amount
            ))
        }

        return rows.sorted {
            // Kategori ber-anggaran duluan, lalu urut pengeluaran terbesar
            let aHas = $0.budgeted != nil
            let bHas = $1.budgeted != nil
            if aHas != bHas { return aHas }
            return $0.spent > $1.spent
        }
    }

    // MARK: - Computed: Income Breakdown
    private var incomeByCategory: [(name: String, amount: Decimal, colorHex: String)] {
        Dictionary(grouping: incomeTx) { $0.category?.name ?? "Lainnya" }
            .map { key, txs in (
                name:     key,
                amount:   txs.reduce(0) { $0 + $1.amount },
                colorHex: txs.first?.category?.colorHex ?? "#4CAF82"
            )}
            .sorted { $0.amount > $1.amount }
    }

    // MARK: - Computed: Pie Chart (Expense)
    private var expenseByCategory: [(name: String, amount: Double, colorHex: String)] {
        budgetTableRows.filter { $0.spent > 0 }.map {
            (name: $0.categoryName,
             amount: NSDecimalNumber(decimal: $0.spent).doubleValue,
             colorHex: $0.colorHex)
        }
    }

    // MARK: - Computed: Monthly Trend (12 bulan)
    private var monthlyTrend: [(month: String, amount: Double)] {
        let cal = Calendar.current
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "id_ID")
        fmt.dateFormat = "MMM"
        var result: [(month: String, amount: Double)] = []
        for i in stride(from: 11, through: 0, by: -1) {
            let comps = DateComponents(year: selectedYear, month: selectedMonth - i)
            let date  = cal.date(from: comps) ?? Date()
            let m = cal.component(.month, from: date)
            let y = cal.component(.year,  from: date)
            let total = dataStore.transactions
                .filter { $0.type == .expense &&
                    cal.component(.month, from: $0.date) == m &&
                    cal.component(.year,  from: $0.date) == y }
                .reduce(Decimal(0)) { $0 + $1.amount }
            result.append((month: fmt.string(from: date),
                           amount: NSDecimalNumber(decimal: total).doubleValue))
        }
        return result
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: CWSpacing.lg) {
                SlideInCard(index: 0) { monthNavigator }
                SlideInCard(index: 1) { summaryCards }
                SlideInCard(index: 2) { budgetTableSection }
                SlideInCard(index: 3) { incomeTableSection }
                SlideInCard(index: 4) { chartsSection }
            }
            .padding(CWSpacing.md)
        }
        .background(Color.cwBackground)
        .navigationTitle("Laporan")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar { toolbarContent }
        .sheet(isPresented: $showShareSheet) {
            if let url = pdfURL {
                ShareSheet(url: url)
            }
        }
    }

    // MARK: - Toolbar
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button {
                exportPDF()
            } label: {
                if isGeneratingPDF {
                    ProgressView().controlSize(.small)
                } else {
                    Label("Export PDF", systemImage: "square.and.arrow.up")
                }
            }
            .disabled(isGeneratingPDF)
        }
    }

    // MARK: - Month Navigator
    private var monthNavigator: some View {
        HStack {
            Button { prevMonth() } label: {
                Image(systemName: "chevron.left")
                    .font(.title3.bold())
                    .foregroundStyle(Color.cwTextSecondary)
                    .padding(.horizontal, CWSpacing.sm)
            }.buttonStyle(.plain)

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
            }.buttonStyle(.plain)
        }
        .padding(.vertical, CWSpacing.sm)
    }

    // MARK: - Summary Cards (4 kartu)
    private var summaryCards: some View {
        VStack(spacing: CWSpacing.sm) {
            HStack(spacing: CWSpacing.sm) {
                summaryCard(label: "Total Pemasukan",  amount: totalIncome,  color: Color(hex: "#4CAF82"))
                summaryCard(label: "Tabungan Bulan Ini", amount: netSaving >= 0 ? netSaving : 0, color: Color(hex: "#1c6cff"))
            }
            HStack(spacing: CWSpacing.sm) {
                summaryCard(label: "Total Pengeluaran", amount: totalExpense,        color: Color(hex: "#FF6B6B"))
                summaryCard(label: "Total Saldo Dompet", amount: totalWalletBalance, color: Color.cwTextPrimary)
            }
        }
    }

    private func summaryCard(label: String, amount: Decimal, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(Color.cwTextSecondary)
            Text(CurrencyFormatter.format(amount))
                .font(.subheadline.bold())
                .foregroundStyle(color)
                .monospacedDigit()
                .minimumScaleFactor(0.7)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(CWSpacing.md)
        .background(Color.cwSurface, in: RoundedRectangle(cornerRadius: CWRadius.md))
        .overlay(RoundedRectangle(cornerRadius: CWRadius.md).stroke(Color.cwBorder, lineWidth: 1))
    }

    // MARK: - Budget Table
    private var budgetTableSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Judul
            Text("Daftar Pengeluaran per Kategori")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.cwTextSecondary)
                .padding(.bottom, CWSpacing.sm)

            VStack(spacing: 0) {
                // Header baris
                budgetTableHeader

                if budgetTableRows.isEmpty {
                    Text("Belum ada pengeluaran bulan ini")
                        .font(.caption)
                        .foregroundStyle(Color.cwTextSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(CWSpacing.lg)
                } else {
                    ForEach(Array(budgetTableRows.enumerated()), id: \.element.id) { idx, row in
                        budgetTableRow(row, isEven: idx.isMultiple(of: 2))
                        if row.id != budgetTableRows.last?.id {
                            Divider().background(Color.cwBorder)
                        }
                    }
                }
            }
            .background(Color.cwSurface, in: RoundedRectangle(cornerRadius: CWRadius.md))
            .clipShape(RoundedRectangle(cornerRadius: CWRadius.md))
        }
    }

    private var budgetTableHeader: some View {
        HStack(spacing: 8) {
            Text("Kategori Pengeluaran")
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("Anggaran 💰")
                .frame(width: 85, alignment: .trailing)
            Text("Realisasi 🔧")
                .frame(width: 85, alignment: .trailing)
            Text("Progres")
                .frame(width: 90, alignment: .leading)
            Text("% Pakai")
                .frame(width: 52, alignment: .trailing)
        }
        .font(.caption.bold())
        .foregroundStyle(.white)
        .padding(.horizontal, CWSpacing.md)
        .padding(.vertical, CWSpacing.sm)
        .background(Color(hex: "#1a6b6b"))
    }

    private func budgetTableRow(_ row: BudgetTableRow, isEven: Bool) -> some View {
        HStack(spacing: 8) {
            // Kategori
            HStack(spacing: 6) {
                Circle()
                    .fill(Color(hex: row.colorHex))
                    .frame(width: 8, height: 8)
                Text(row.categoryName)
                    .font(.subheadline)
                    .foregroundStyle(Color.cwTextPrimary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Anggaran
            Text(row.budgeted != nil ? CurrencyFormatter.formatShort(row.budgeted!) : "-")
                .font(.caption.monospacedDigit())
                .foregroundStyle(Color.cwTextSecondary)
                .frame(width: 85, alignment: .trailing)

            // Realisasi
            Text(CurrencyFormatter.formatShort(row.spent))
                .font(.caption.bold().monospacedDigit())
                .foregroundStyle(row.isOverBudget ? Color(hex: "#FF6B6B") : Color.cwTextPrimary)
                .frame(width: 85, alignment: .trailing)

            // Progress Bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.cwBorder)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(row.statusColor)
                        .frame(width: geo.size.width * min(row.progress, 1.0))
                }
            }
            .frame(width: 90, height: 10)

            // Persentase
            Text(row.budgeted != nil ? String(format: "%.2f%%", row.percentage) : "-")
                .font(.caption.monospacedDigit())
                .foregroundStyle(row.isOverBudget ? Color(hex: "#FF6B6B") : Color.cwTextSecondary)
                .frame(width: 52, alignment: .trailing)
        }
        .padding(.horizontal, CWSpacing.md)
        .padding(.vertical, 10)
        .background(isEven ? Color.cwSurface : Color.cwBackground.opacity(0.5))
    }

    // MARK: - Income Table
    private var incomeTableSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Rincian Pemasukan per Kategori")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.cwTextSecondary)
                .padding(.bottom, CWSpacing.sm)

            VStack(spacing: 0) {
                // Header
                HStack(spacing: 8) {
                    Text("Sumber Pemasukan")
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("Jumlah")
                        .frame(width: 110, alignment: .trailing)
                    Text("% dari Total")
                        .frame(width: 85, alignment: .trailing)
                }
                .font(.caption.bold())
                .foregroundStyle(.white)
                .padding(.horizontal, CWSpacing.md)
                .padding(.vertical, CWSpacing.sm)
                .background(Color(hex: "#1a6b6b"))

                if incomeByCategory.isEmpty {
                    Text("Belum ada pemasukan bulan ini")
                        .font(.caption)
                        .foregroundStyle(Color.cwTextSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(CWSpacing.lg)
                } else {
                    ForEach(Array(incomeByCategory.enumerated()), id: \.element.name) { idx, item in
                        HStack(spacing: 8) {
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(Color(hex: item.colorHex))
                                    .frame(width: 8, height: 8)
                                Text(item.name)
                                    .font(.subheadline)
                                    .foregroundStyle(Color.cwTextPrimary)
                                    .lineLimit(1)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)

                            Text(CurrencyFormatter.formatShort(item.amount))
                                .font(.caption.bold().monospacedDigit())
                                .foregroundStyle(Color(hex: "#4CAF82"))
                                .frame(width: 110, alignment: .trailing)

                            let pct = totalIncome > 0
                                ? Int(NSDecimalNumber(decimal: item.amount / totalIncome).doubleValue * 100)
                                : 0
                            Text("\(pct)%")
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(Color.cwTextSecondary)
                                .frame(width: 85, alignment: .trailing)
                        }
                        .padding(.horizontal, CWSpacing.md)
                        .padding(.vertical, 10)
                        .background(idx.isMultiple(of: 2) ? Color.cwSurface : Color.cwBackground.opacity(0.5))
                        if item.name != incomeByCategory.last?.name {
                            Divider().background(Color.cwBorder)
                        }
                    }
                }
            }
            .background(Color.cwSurface, in: RoundedRectangle(cornerRadius: CWRadius.md))
            .clipShape(RoundedRectangle(cornerRadius: CWRadius.md))
        }
    }

    // MARK: - Charts Section
    private var chartsSection: some View {
        VStack(spacing: CWSpacing.lg) {
            // Grafik Donat
            VStack(alignment: .leading, spacing: CWSpacing.sm) {
                Text("Distribusi Pengeluaran per Kategori")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.cwTextSecondary)

                if expenseByCategory.isEmpty {
                    emptyChartPlaceholder(icon: "chart.pie.fill", text: "Belum ada data pengeluaran")
                } else {
                    Chart(expenseByCategory, id: \.name) { item in
                        SectorMark(
                            angle: .value("Jumlah", item.amount),
                            innerRadius: .ratio(0.5),
                            angularInset: 2
                        )
                        .foregroundStyle(Color(hex: item.colorHex))
                        .cornerRadius(4)
                        .annotation(position: .overlay) {
                            if item.amount / (expenseByCategory.reduce(0) { $0 + $1.amount }) > 0.08 {
                                Text(item.name)
                                    .font(.system(size: 9, weight: .semibold))
                                    .foregroundStyle(.white)
                                    .multilineTextAlignment(.center)
                            }
                        }
                    }
                    .frame(height: 220)
                }
            }
            .padding(CWSpacing.md)
            .background(Color.cwSurface, in: RoundedRectangle(cornerRadius: CWRadius.md))

            // Tren Bulanan
            VStack(alignment: .leading, spacing: CWSpacing.sm) {
                Text("Tren Pengeluaran 12 Bulan")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.cwTextSecondary)

                Chart(monthlyTrend, id: \.month) { item in
                    BarMark(
                        x: .value("Bulan", item.month),
                        y: .value("Jumlah", item.amount)
                    )
                    .foregroundStyle(Color(hex: "#1a9b9b").gradient)
                    .cornerRadius(4)
                }
                .frame(height: 180)
                .chartYAxis {
                    AxisMarks { val in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(Color.cwBorder)
                        AxisValueLabel {
                            if let dbl = val.as(Double.self) {
                                Text(CurrencyFormatter.formatShort(Decimal(dbl)))
                                    .font(.system(size: 9))
                                    .foregroundStyle(Color.cwTextSecondary)
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks { _ in
                        AxisValueLabel()
                            .font(.system(size: 9))
                            .foregroundStyle(Color.cwTextSecondary)
                    }
                }
            }
            .padding(CWSpacing.md)
            .background(Color.cwSurface, in: RoundedRectangle(cornerRadius: CWRadius.md))
        }
    }

    private func emptyChartPlaceholder(icon: String, text: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon).font(.largeTitle).foregroundStyle(Color.cwTextSecondary)
            Text(text).font(.caption).foregroundStyle(Color.cwTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 200)
    }

    // MARK: - PDF Export
    private func exportPDF() {
        isGeneratingPDF = true
        Task {
            let pdfView = ReportPDFContent(
                monthTitle:      monthTitle,
                totalIncome:     totalIncome,
                totalExpense:    totalExpense,
                netSaving:       netSaving,
                walletBalance:   totalWalletBalance,
                budgetRows:      budgetTableRows,
                incomeRows:      incomeByCategory,
                expenseChart:    expenseByCategory,
                monthlyTrend:    monthlyTrend
            )
            pdfURL = await PDFExporter.generateURL(for: pdfView, filename: "CashWay-\(monthTitle)")
            isGeneratingPDF = false
            if pdfURL != nil { showShareSheet = true }
        }
    }

    // MARK: - Helpers
    private var monthTitle: String {
        let f = DateFormatter(); f.locale = Locale(identifier: "id_ID"); f.dateFormat = "MMMM yyyy"
        return f.string(from: Calendar.current.date(
            from: DateComponents(year: selectedYear, month: selectedMonth)) ?? .now)
    }
    private func prevMonth() {
        if selectedMonth == 1 { selectedMonth = 12; selectedYear -= 1 } else { selectedMonth -= 1 }
    }
    private func nextMonth() {
        if selectedMonth == 12 { selectedMonth = 1; selectedYear += 1 } else { selectedMonth += 1 }
    }
}

// MARK: - ShareSheet (cross-platform)
#if os(iOS)
import UIKit
struct ShareSheet: UIViewControllerRepresentable {
    let url: URL
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [url], applicationActivities: nil)
    }
    func updateUIViewController(_ uvc: UIActivityViewController, context: Context) {}
}
#elseif os(macOS)
struct ShareSheet: View {
    let url: URL
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.fill").font(.largeTitle).foregroundStyle(Color.cwAccent)
            Text("PDF siap!").font(.headline)
            Text(url.lastPathComponent).font(.caption).foregroundStyle(.secondary)
            HStack {
                Button("Buka di Finder") {
                    NSWorkspace.shared.activateFileViewerSelecting([url])
                }
                Button("Salin Lokasi File") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(url.path, forType: .string)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(32)
        .frame(width: 320)
    }
}
#endif

#Preview {
    NavigationStack { ReportsView() }
        .environmentObject(DataStore())
        .preferredColorScheme(.dark)
}
