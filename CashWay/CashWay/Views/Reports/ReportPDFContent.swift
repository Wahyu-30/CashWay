import SwiftUI
import Charts

// ============================================================
// MARK: - ReportPDFContent
// Tampilan khusus untuk PDF — latar putih, cocok untuk cetak.
// Dibuat terpisah agar PDF bisa berbeda tema dari app (dark).
// ============================================================

struct ReportPDFContent: View {

    let monthTitle:   String
    let totalIncome:  Decimal
    let totalExpense: Decimal
    let netSaving:    Decimal
    let walletBalance: Decimal
    let budgetRows:   [BudgetTableRow]
    let incomeRows:   [(name: String, amount: Decimal, colorHex: String)]
    let expenseChart: [(name: String, amount: Double, colorHex: String)]
    let monthlyTrend: [(month: String, amount: Double)]

    private let teal = Color(hex: "#1a6b6b")
    private let tableHeaderBg = Color(hex: "#1a6b6b")

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {

            // HEADER
            ZStack {
                Rectangle().fill(teal)
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("LAPORAN KEUANGAN BULANAN")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.white)
                        Text("CashWay — Pelacak Keuangan Pribadi")
                            .font(.system(size: 11))
                            .foregroundStyle(.white.opacity(0.85))
                    }
                    Spacer()
                    Text(monthTitle)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
            }

            // SUMMARY CARDS
            HStack(spacing: 12) {
                pdfSummaryCard(label: "Total Pemasukan",   value: totalIncome,   color: Color(hex: "#1a8a5a"))
                pdfSummaryCard(label: "Tabungan Bulan Ini", value: netSaving >= 0 ? netSaving : 0, color: Color(hex: "#1a6cff"))
                pdfSummaryCard(label: "Total Pengeluaran", value: totalExpense,  color: Color(hex: "#cc3333"))
                pdfSummaryCard(label: "Saldo Dompet",      value: walletBalance, color: Color(hex: "#222222"))
            }
            .padding(.horizontal, 24)

            // TABEL ANGGARAN
            VStack(alignment: .leading, spacing: 6) {
                Text("Daftar Pengeluaran per Kategori")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color(hex: "#444444"))
                    .padding(.horizontal, 24)

                VStack(spacing: 0) {
                    // Header
                    HStack(spacing: 6) {
                        Text("Kategori Pengeluaran").frame(maxWidth: .infinity, alignment: .leading)
                        Text("Anggaran 💰").frame(width: 90, alignment: .trailing)
                        Text("Realisasi 🔧").frame(width: 90, alignment: .trailing)
                        Text("Progres Penggunaan Anggaran").frame(width: 130, alignment: .leading)
                        Text("% Pakai").frame(width: 55, alignment: .trailing)
                    }
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(tableHeaderBg)

                    ForEach(Array(budgetRows.enumerated()), id: \.element.id) { idx, row in
                        HStack(spacing: 6) {
                            HStack(spacing: 5) {
                                Circle().fill(Color(hex: row.colorHex)).frame(width: 7, height: 7)
                                Text(row.categoryName).lineLimit(1)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)

                            Text(row.budgeted != nil ? CurrencyFormatter.formatShort(row.budgeted!) : "-")
                                .frame(width: 90, alignment: .trailing)
                                .foregroundStyle(Color(hex: "#555555"))

                            Text(CurrencyFormatter.formatShort(row.spent))
                                .frame(width: 90, alignment: .trailing)
                                .foregroundStyle(row.isOverBudget ? Color(hex: "#cc3333") : Color(hex: "#111111"))
                                .fontWeight(row.isOverBudget ? .bold : .regular)

                            // Progress bar
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 2).fill(Color(hex: "#dddddd"))
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(row.statusColor)
                                        .frame(width: geo.size.width * min(row.progress, 1.0))
                                }
                            }
                            .frame(width: 130, height: 8)

                            Text(row.budgeted != nil ? String(format: "%.2f%%", row.percentage) : "-")
                                .frame(width: 55, alignment: .trailing)
                                .foregroundStyle(row.isOverBudget ? Color(hex: "#cc3333") : Color(hex: "#444444"))
                                .fontWeight(row.isOverBudget ? .bold : .regular)
                        }
                        .font(.system(size: 10))
                        .padding(.horizontal, 16)
                        .padding(.top, 7)
                        .padding(.bottom, row.subRows.isEmpty ? 7 : 2)
                        .background(idx.isMultiple(of: 2) ? Color.white : Color(hex: "#f5f8f8"))
                        
                        if !row.subRows.isEmpty {
                            VStack(spacing: 0) {
                                ForEach(row.subRows) { sub in
                                    HStack(spacing: 6) {
                                        HStack(spacing: 5) {
                                            Rectangle().fill(Color(hex: "#cccccc")).frame(width: 1, height: 16).padding(.leading, 3)
                                            Circle().fill(Color(hex: sub.colorHex).opacity(0.5)).frame(width: 5, height: 5)
                                            Text(sub.categoryName).lineLimit(1).foregroundStyle(Color(hex: "#666666"))
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        
                                        Text("").frame(width: 90, alignment: .trailing)
                                        Text(CurrencyFormatter.formatShort(sub.spent))
                                            .frame(width: 90, alignment: .trailing)
                                            .foregroundStyle(Color(hex: "#666666"))
                                        Spacer().frame(width: 130 + 55 + 6)
                                    }
                                    .font(.system(size: 9))
                                    .padding(.horizontal, 16)
                                    .padding(.bottom, 4)
                                }
                            }
                            .padding(.bottom, 4)
                            .background(idx.isMultiple(of: 2) ? Color.white : Color(hex: "#f5f8f8"))
                        }

                        Divider().foregroundStyle(Color(hex: "#e0e0e0"))
                    }
                }
                .background(Color.white)
                .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color(hex: "#dddddd"), lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .padding(.horizontal, 24)
            }

            // TABEL PEMASUKAN
            VStack(alignment: .leading, spacing: 6) {
                Text("Rincian Pemasukan per Kategori")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color(hex: "#444444"))
                    .padding(.horizontal, 24)

                VStack(spacing: 0) {
                    HStack(spacing: 6) {
                        Text("Sumber Pemasukan").frame(maxWidth: .infinity, alignment: .leading)
                        Text("Jumlah").frame(width: 120, alignment: .trailing)
                        Text("% dari Total").frame(width: 80, alignment: .trailing)
                    }
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16).padding(.vertical, 8)
                    .background(tableHeaderBg)

                    ForEach(Array(incomeRows.enumerated()), id: \.element.name) { idx, item in
                        HStack(spacing: 6) {
                            HStack(spacing: 5) {
                                Circle().fill(Color(hex: item.colorHex)).frame(width: 7, height: 7)
                                Text(item.name).lineLimit(1)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            Text(CurrencyFormatter.formatShort(item.amount))
                                .frame(width: 120, alignment: .trailing)
                                .foregroundStyle(Color(hex: "#1a8a5a")).fontWeight(.semibold)
                            let pct = totalIncome > 0
                                ? Int(NSDecimalNumber(decimal: item.amount / totalIncome).doubleValue * 100)
                                : 0
                            Text("\(pct)%")
                                .frame(width: 80, alignment: .trailing)
                                .foregroundStyle(Color(hex: "#555555"))
                        }
                        .font(.system(size: 10))
                        .padding(.horizontal, 16).padding(.vertical, 7)
                        .background(idx.isMultiple(of: 2) ? Color.white : Color(hex: "#f5f8f8"))
                        Divider().foregroundStyle(Color(hex: "#e0e0e0"))
                    }
                }
                .background(Color.white)
                .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color(hex: "#dddddd"), lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .padding(.horizontal, 24)
            }

            // GRAFIK
            HStack(alignment: .top, spacing: 16) {
                // Donut
                VStack(alignment: .leading, spacing: 6) {
                    Text("Distribusi Pengeluaran per Kategori")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color(hex: "#444444"))
                    if !expenseChart.isEmpty {
                        Chart(expenseChart, id: \.name) { item in
                            SectorMark(angle: .value("Jumlah", item.amount), innerRadius: .ratio(0.45), angularInset: 1.5)
                                .foregroundStyle(Color(hex: item.colorHex))
                                .cornerRadius(3)
                                .annotation(position: .overlay) {
                                    if item.amount / (expenseChart.reduce(0) { $0 + $1.amount }) > 0.08 {
                                        Text(item.name)
                                            .font(.system(size: 8, weight: .bold))
                                            .foregroundStyle(.white)
                                            .shadow(color: .black.opacity(0.7), radius: 1, x: 0, y: 1)
                                            .multilineTextAlignment(.center)
                                            .lineLimit(2)
                                            .minimumScaleFactor(0.5)
                                            .padding(.horizontal, 2)
                                    }
                                }
                        }
                        .frame(height: 180)
                        
                        let groupRows = budgetRows.filter { !$0.subRows.isEmpty && $0.spent > 0 }
                        if !groupRows.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Keterangan Bagan:")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(Color(hex: "#666666"))
                                    .padding(.top, 8)
                                    
                                ForEach(groupRows) { row in
                                    HStack(alignment: .top, spacing: 5) {
                                        Circle().fill(Color(hex: row.colorHex)).frame(width: 6, height: 6).padding(.top, 3)
                                        VStack(alignment: .leading, spacing: 1) {
                                            Text(row.categoryName)
                                                .font(.system(size: 9, weight: .bold))
                                                .foregroundStyle(Color(hex: "#333333"))
                                            Text(row.subRows.map { $0.categoryName }.joined(separator: ", "))
                                                .font(.system(size: 8))
                                                .foregroundStyle(Color(hex: "#777777"))
                                        }
                                    }
                                }
                            }
                            .padding(.top, 2)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(12)
                .background(Color.white)
                .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color(hex: "#dddddd"), lineWidth: 1))

                // Bar chart tren
                VStack(alignment: .leading, spacing: 6) {
                    Text("Tren Pengeluaran 12 Bulan")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color(hex: "#444444"))
                    Chart(monthlyTrend, id: \.month) { item in
                        BarMark(x: .value("Bulan", item.month), y: .value("Jumlah", item.amount))
                            .foregroundStyle(Color(hex: "#1a9b9b").gradient)
                            .cornerRadius(3)
                    }
                    .frame(height: 180)
                    .chartXAxis {
                        AxisMarks { _ in
                            AxisValueLabel().font(.system(size: 8)).foregroundStyle(Color(hex: "#555555"))
                        }
                    }
                    .chartYAxis {
                        AxisMarks { val in
                            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            AxisValueLabel {
                                if let d = val.as(Double.self) {
                                    Text(CurrencyFormatter.formatCompact(Decimal(d)))
                                        .font(.system(size: 7))
                                }
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(12)
                .background(Color.white)
                .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color(hex: "#dddddd"), lineWidth: 1))
            }
            .padding(.horizontal, 24)

            // FOOTER
            Divider().padding(.horizontal, 24)
            Text("Dicetak dari CashWay  •  \(monthTitle)")
                .font(.system(size: 9))
                .foregroundStyle(Color(hex: "#999999"))
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.bottom, 16)
        }
        .background(Color(hex: "#f7f9f9"))
        .frame(width: 750) // Lebar tetap agar PDF konsisten
    }

    private func pdfSummaryCard(label: String, value: Decimal, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.system(size: 9)).foregroundStyle(Color(hex: "#666666"))
            Text(CurrencyFormatter.formatShort(value))
                .font(.system(size: 13, weight: .bold)).foregroundStyle(color)
                .minimumScaleFactor(0.6).lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color.white)
        .overlay(RoundedRectangle(cornerRadius: 4).stroke(teal.opacity(0.4), lineWidth: 1))
    }
}
