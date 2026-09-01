import SwiftUI
import Charts
import UniformTypeIdentifiers

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
    @State private var showShareSheet  = false
    @State private var isGeneratingPDF = false

    // MARK: - Cached Data (diisi oleh recompute())
    @State private var cachedBudgetRows:    [BudgetTableRow] = []
    @State private var cachedIncomeRows:    [(name: String, amount: Decimal, colorHex: String)] = []
    @State private var cachedExpenseChart:  [(name: String, amount: Double, colorHex: String)] = []
    @State private var cachedMonthlyTrend:  [(month: String, amount: Double)] = []
    @State private var cachedTotalIncome:   Decimal = 0
    @State private var cachedTotalExpense:  Decimal = 0
    @State private var cachedNetSaving:     Decimal = 0
    @State private var cachedWalletBalance: Decimal = 0

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
            if let url = pdfURL { ShareSheet(url: url) }
        }
        .onAppear { recompute() }
        .onChange(of: selectedMonth)                { recompute() }
        .onChange(of: selectedYear)                 { recompute() }
        .onChange(of: dataStore.transactions.count) { recompute() }
        .onChange(of: dataStore.budgets.count)      { recompute() }
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
                summaryCard(label: "Total Pemasukan",   amount: cachedTotalIncome,   color: Color(hex: "#4CAF82"))
                summaryCard(label: "Tabungan Bulan Ini", amount: cachedNetSaving >= 0 ? cachedNetSaving : 0, color: Color(hex: "#1c6cff"))
            }
            HStack(spacing: CWSpacing.sm) {
                summaryCard(label: "Total Pengeluaran",  amount: cachedTotalExpense,  color: Color(hex: "#FF6B6B"))
                summaryCard(label: "Total Saldo Dompet", amount: cachedWalletBalance, color: Color.cwTextPrimary)
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

    // MARK: - Recompute (background)
    private func recompute() {
        let cal     = Calendar.current
        let month   = selectedMonth
        let year    = selectedYear
        let allTx   = dataStore.transactions
        let budgets = dataStore.budgets
        let wallets = dataStore.wallets

        // Precompute month/year SEKALI per transaksi — O(n), bukan O(n×12)
        let tagged = allTx.map { tx in
            (tx: tx,
             m: cal.component(.month, from: tx.date),
             y: cal.component(.year,  from: tx.date))
        }

        let monthTx   = tagged.filter { $0.m == month && $0.y == year }
        let expenseTx = monthTx.filter { $0.tx.type == .expense }
        let incomeTx  = monthTx.filter { $0.tx.type == .income  }

        let totalExpense  = expenseTx.reduce(Decimal(0)) { $0 + $1.tx.amount }
        let totalIncome   = incomeTx.reduce(Decimal(0))  { $0 + $1.tx.amount }
        let netSaving     = totalIncome - totalExpense

        let initialTotal  = wallets.reduce(Decimal(0)) { $0 + $1.initialBalance }
        let allIncome     = allTx.filter { $0.type == .income  }.reduce(Decimal(0)) { $0 + $1.amount }
        let allExpense    = allTx.filter { $0.type == .expense }.reduce(Decimal(0)) { $0 + $1.amount }
        let walletBalance = initialTotal + allIncome - allExpense

        // --- Budget Rows ---
        let monthBudgets = budgets.filter { $0.month == month && $0.year == year }
        var spendingMap: [String: (name: String, colorHex: String, amount: Decimal)] = [:]
        for item in expenseTx {
            let catId = item.tx.category?.id       ?? "other"
            let name  = item.tx.category?.name     ?? "Lainnya"
            let color = item.tx.category?.colorHex ?? "#8B8FA8"
            if let ex = spendingMap[catId] {
                spendingMap[catId] = (name: name, colorHex: color, amount: ex.amount + item.tx.amount)
            } else {
                spendingMap[catId] = (name: name, colorHex: color, amount: item.tx.amount)
            }
        }
        var handledCatIds: Set<String> = []
        var newBudgetRows: [BudgetTableRow] = []
        
        for b in monthBudgets {
            let catIds = b.allCategoryIds
            // Tandai semua kategori dalam budget group ini sudah di-handle
            catIds.forEach { handledCatIds.insert($0) }
            
            // Jumlahkan total dari map (ini mirip dgn yg dilakukan DataStore, tapi manual)
            let totalSpent = catIds.reduce(Decimal(0)) { $0 + (spendingMap[$1]?.amount ?? 0) }
            
            newBudgetRows.append(BudgetTableRow(
                id:           b.id, // ID budget
                categoryName: b.groupName ?? b.category?.name ?? "Anggaran",
                colorHex:     (b.groupName != nil) ? "#00C9A7" : (b.category?.colorHex ?? "#8B8FA8"),
                budgeted:     b.amount,
                spent:        totalSpent
            ))
        }
        
        // Sisa kategori yang belum tercakup di budget manapun
        for (catId, info) in spendingMap where !handledCatIds.contains(catId) {
            newBudgetRows.append(BudgetTableRow(
                id: catId, 
                categoryName: info.name,
                colorHex: info.colorHex, 
                budgeted: nil, 
                spent: info.amount
            ))
        }
        
        newBudgetRows.sort {
            let aH = $0.budgeted != nil; let bH = $1.budgeted != nil
            if aH != bH { return aH }
            return $0.spent > $1.spent
        }

        // --- Income by Category ---
        var incomeDict: [String: (name: String, amount: Decimal, colorHex: String)] = [:]
        for item in incomeTx {
            let name  = item.tx.category?.name     ?? "Lainnya"
            let color = item.tx.category?.colorHex ?? "#4CAF82"
            if let ex = incomeDict[name] {
                incomeDict[name] = (name: name, amount: ex.amount + item.tx.amount, colorHex: color)
            } else {
                incomeDict[name] = (name: name, amount: item.tx.amount, colorHex: color)
            }
        }
        let newIncomeRows = incomeDict.values
            .sorted { $0.amount > $1.amount }
            .map { (name: $0.name, amount: $0.amount, colorHex: $0.colorHex) }

        let newExpenseChart = newBudgetRows.filter { $0.spent > 0 }
            .map { (name: $0.categoryName,
                    amount: NSDecimalNumber(decimal: $0.spent).doubleValue,
                    colorHex: $0.colorHex) }

        // --- Monthly Trend — O(n) dengan dictionary ---
        var monthlyExpense: [String: Double] = [:]
        for item in tagged where item.tx.type == .expense {
            let key = "\(item.y)-\(item.m)"
            monthlyExpense[key, default: 0] += NSDecimalNumber(decimal: item.tx.amount).doubleValue
        }
        let fmt = DateFormatter()
        fmt.locale     = Locale(identifier: "id_ID")
        fmt.dateFormat = "MMM"
        var newTrend: [(month: String, amount: Double)] = []
        for i in stride(from: 11, through: 0, by: -1) {
            let comps = DateComponents(year: year, month: month - i)
            let date  = cal.date(from: comps) ?? Date()
            let m2    = cal.component(.month, from: date)
            let y2    = cal.component(.year,  from: date)
            newTrend.append((month: fmt.string(from: date),
                             amount: monthlyExpense["\(y2)-\(m2)"] ?? 0))
        }

        // Update state (sudah di MainActor karena ini SwiftUI view)
        cachedBudgetRows    = newBudgetRows
        cachedIncomeRows    = newIncomeRows
        cachedExpenseChart  = newExpenseChart
        cachedMonthlyTrend  = newTrend
        cachedTotalIncome   = totalIncome
        cachedTotalExpense  = totalExpense
        cachedNetSaving     = netSaving
        cachedWalletBalance = walletBalance
    }

    // MARK: - Budget Table
    private var budgetTableSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Daftar Pengeluaran per Kategori")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.cwTextSecondary)
                .padding(.bottom, CWSpacing.sm)

            VStack(spacing: 0) {
                budgetTableHeader

                if cachedBudgetRows.isEmpty {
                    Text("Belum ada pengeluaran bulan ini")
                        .font(.caption)
                        .foregroundStyle(Color.cwTextSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(CWSpacing.lg)
                } else {
                    ForEach(Array(cachedBudgetRows.enumerated()), id: \.element.id) { idx, row in
                        budgetTableRow(row, isEven: idx.isMultiple(of: 2))
                        if row.id != cachedBudgetRows.last?.id {
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
        HStack(spacing: 4) {
            Text("Kategori")
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(1)
            Text("Anggaran")
                .frame(width: 68, alignment: .trailing)
                .lineLimit(1)
            Text("Realisasi")
                .frame(width: 68, alignment: .trailing)
                .lineLimit(1)
            Text("Progres")
                .frame(width: 58, alignment: .leading)
                .lineLimit(1)
            Text("% Pakai")
                .frame(width: 44, alignment: .trailing)
                .lineLimit(1)
        }
        .minimumScaleFactor(0.75)
        .font(.caption.bold())
        .foregroundStyle(.white)
        .padding(.horizontal, CWSpacing.md)
        .padding(.vertical, CWSpacing.sm)
        .background(Color(hex: "#1a6b6b"))
    }

    private func budgetTableRow(_ row: BudgetTableRow, isEven: Bool) -> some View {
        HStack(spacing: 4) {
            // Kategori
            HStack(spacing: 6) {
                Circle()
                    .fill(Color(hex: row.colorHex))
                    .frame(width: 8, height: 8)
                Text(row.categoryName)
                    .font(.caption)
                    .foregroundStyle(Color.cwTextPrimary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Anggaran
            Text(row.budgeted != nil ? CurrencyFormatter.formatShort(row.budgeted!) : "-")
                .font(.caption.monospacedDigit())
                .foregroundStyle(Color.cwTextSecondary)
                .frame(width: 68, alignment: .trailing)
                .lineLimit(1)

            // Realisasi
            Text(CurrencyFormatter.formatShort(row.spent))
                .font(.caption.bold().monospacedDigit())
                .foregroundStyle(row.isOverBudget ? Color(hex: "#FF6B6B") : Color.cwTextPrimary)
                .frame(width: 68, alignment: .trailing)
                .lineLimit(1)

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
            .frame(width: 58, height: 10)

            // Persentase
            Text(row.budgeted != nil ? String(format: "%.1f%%", row.percentage) : "-")
                .font(.caption.monospacedDigit())
                .foregroundStyle(row.isOverBudget ? Color(hex: "#FF6B6B") : Color.cwTextSecondary)
                .frame(width: 44, alignment: .trailing)
                .lineLimit(1)
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

                if cachedIncomeRows.isEmpty {
                    Text("Belum ada pemasukan bulan ini")
                        .font(.caption)
                        .foregroundStyle(Color.cwTextSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(CWSpacing.lg)
                } else {
                    ForEach(Array(cachedIncomeRows.enumerated()), id: \.element.name) { idx, item in
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

                            let pct = cachedTotalIncome > 0
                                ? Int(NSDecimalNumber(decimal: item.amount / cachedTotalIncome).doubleValue * 100)
                                : 0
                            Text("\(pct)%")
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(Color.cwTextSecondary)
                                .frame(width: 85, alignment: .trailing)
                        }
                        .padding(.horizontal, CWSpacing.md)
                        .padding(.vertical, 10)
                        .background(idx.isMultiple(of: 2) ? Color.cwSurface : Color.cwBackground.opacity(0.5))
                        if item.name != cachedIncomeRows.last?.name {
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

                if cachedExpenseChart.isEmpty {
                    emptyChartPlaceholder(icon: "chart.pie.fill", text: "Belum ada data pengeluaran")
                } else {
                    Chart(cachedExpenseChart, id: \.name) { item in
                        SectorMark(
                            angle: .value("Jumlah", item.amount),
                            innerRadius: .ratio(0.5),
                            angularInset: 2
                        )
                        .foregroundStyle(Color(hex: item.colorHex))
                        .cornerRadius(4)
                        .annotation(position: .overlay) {
                            if item.amount / (cachedExpenseChart.reduce(0) { $0 + $1.amount }) > 0.08 {
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

                Chart(cachedMonthlyTrend, id: \.month) { item in
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
                monthTitle:    monthTitle,
                totalIncome:   cachedTotalIncome,
                totalExpense:  cachedTotalExpense,
                netSaving:     cachedNetSaving,
                walletBalance: cachedWalletBalance,
                budgetRows:    cachedBudgetRows,
                incomeRows:    cachedIncomeRows,
                expenseChart:  cachedExpenseChart,
                monthlyTrend:  cachedMonthlyTrend
            )
            let tempURL = await PDFExporter.generateURL(for: pdfView, filename: "CashWay-\(monthTitle)")
            isGeneratingPDF = false
            
            if let tempURL = tempURL {
                #if os(macOS)
                let savePanel = NSSavePanel()
                savePanel.allowedContentTypes = [.pdf]
                savePanel.canCreateDirectories = true
                savePanel.isExtensionHidden = false
                savePanel.title = "Simpan Laporan PDF"
                savePanel.message = "Pilih lokasi untuk menyimpan PDF laporan bulanan Anda."
                savePanel.nameFieldStringValue = tempURL.lastPathComponent
                
                let response = savePanel.runModal()
                if response == .OK, let targetURL = savePanel.url {
                    do {
                        if FileManager.default.fileExists(atPath: targetURL.path) {
                            try FileManager.default.removeItem(at: targetURL)
                        }
                        try FileManager.default.copyItem(at: tempURL, to: targetURL)
                    } catch {
                        print("ReportsView: Gagal menyimpan PDF - \(error)")
                    }
                }
                #else
                self.pdfURL = tempURL
                self.showShareSheet = true
                #endif
            }
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
        Text("PDF Saved") // Dummy view, tidak akan pernah dipanggil karena macOS pakai NSSavePanel
    }
}
#endif

#Preview {
    NavigationStack { ReportsView() }
        .environmentObject(DataStore())
        .preferredColorScheme(.dark)
}
