import Foundation

// ============================================================
// MARK: - SmartAdviceEngine
// Engine yang menganalisis data keuangan dan menghasilkan saran otomatis.
// Ini adalah rule-based system (bukan AI sebenarnya).
// Dipanggil dari DashboardViewModel.
// ============================================================

struct SmartAdviceEngine {

    let monthlySalary: Decimal   // Gaji pokok dari UserDefaults key "monthlySalary"
    let month: Int               // Bulan yang dianalisis (1-12)
    let year: Int                // Tahun yang dianalisis

    // MARK: - Main Entry Point

    /// Hasilkan semua saran untuk bulan ini, diurutkan dari prioritas tertinggi.
    func generateAdvice(transactions: [Transaction], budgets: [Budget]) -> [SmartAdvice] {
        let monthTx = monthlyTransactions(from: transactions)
        let totalExpense  = sum(monthTx, type: .expense)
        let totalIncome   = sum(monthTx, type: .income)
        let _ = salarySum(monthTx)
        let freelanceIncome = freelanceSum(monthTx)

        var advices: [SmartAdvice] = []

        // 1. Cek budget per kategori
        for budget in budgets where budget.month == month && budget.year == year {
            if budget.isOverBudget   { advices.append(makeOverBudgetAdvice(budget)) }
            else if budget.isNearLimit { advices.append(makeNearLimitAdvice(budget)) }
        }

        // 2. Total pengeluaran vs gaji pokok
        advices += spendingVsSalaryAdvice(totalExpense: totalExpense, salary: monthlySalary)

        // 3. Saran alokasi freelance jika ada
        if freelanceIncome > 0 {
            advices.append(makeFreelanceAdvice(amount: freelanceIncome))
        }

        // 4. Cek tabungan (income vs expense)
        advices += savingsAdvice(income: totalIncome, expense: totalExpense)

        // 5. Proyeksi pengeluaran akhir bulan
        if let projection = projectionAdvice(currentExpense: totalExpense) {
            advices.append(projection)
        }

        // Urutkan dari prioritas tertinggi
        return advices.sorted { $0.priority.rawValue > $1.priority.rawValue }
    }

    // MARK: - Private Helpers

    private func monthlyTransactions(from all: [Transaction]) -> [Transaction] {
        let cal = Calendar.current
        return all.filter {
            cal.component(.month, from: $0.date) == month &&
            cal.component(.year,  from: $0.date) == year
        }
    }

    private func sum(_ txs: [Transaction], type: Transaction.TransactionType) -> Decimal {
        txs.filter { $0.type == type }.reduce(Decimal(0)) { $0 + $1.amount }
    }

    private func salarySum(_ txs: [Transaction]) -> Decimal {
        txs.filter { $0.type == .income && $0.incomeTag == .salary }
           .reduce(Decimal(0)) { $0 + $1.amount }
    }

    private func freelanceSum(_ txs: [Transaction]) -> Decimal {
        txs.filter { $0.type == .income && $0.incomeTag == .business }
           .reduce(Decimal(0)) { $0 + $1.amount }
    }

    // MARK: - Advice Makers

    private func makeOverBudgetAdvice(_ budget: Budget) -> SmartAdvice {
        let catName   = budget.category?.name ?? "Kategori"
        let excess    = budget.spent - budget.amount
        let overPct   = Int((budget.percentage - 1.0) * 100)
        let tip       = specificTip(for: catName, excess: excess)

        return SmartAdvice(
            type:      .overBudget,
            priority:  .high,
            title:     "⚠️ Budget \(catName) Terlampaui",
            message:   "Pengeluaran \(catName) sudah melebihi budget \(overPct)% " +
                       "(\(CurrencyFormatter.format(excess)) lebih dari batas). \(tip)",
            action:    "Lihat transaksi \(catName)",
            category:  catName
        )
    }

    private func makeNearLimitAdvice(_ budget: Budget) -> SmartAdvice {
        let catName  = budget.category?.name ?? "Kategori"
        let pct      = Int(budget.percentage * 100)
        let remaining = budget.remaining

        return SmartAdvice(
            type:     .nearLimit,
            priority: .medium,
            title:    "💛 Budget \(catName) Hampir Habis",
            message:  "Sudah terpakai \(pct)% dari budget \(catName). " +
                      "Sisa: \(CurrencyFormatter.format(remaining)). " +
                      "Pertimbangkan untuk lebih hemat hingga akhir bulan.",
            action:   "Kelola budget",
            category: catName
        )
    }

    private func spendingVsSalaryAdvice(totalExpense: Decimal, salary: Decimal) -> [SmartAdvice] {
        guard salary > 0 else { return [] }
        let ratio   = NSDecimalNumber(decimal: totalExpense / salary).doubleValue
        let remaining = salary - totalExpense

        if ratio > 1.0 {
            let excess = totalExpense - salary
            return [SmartAdvice(
                type:     .overspending,
                priority: .high,
                title:    "🔴 Pengeluaran Melebihi Gaji Pokok!",
                message:  "Total pengeluaran bulan ini \(CurrencyFormatter.format(totalExpense)) " +
                          "sudah melebihi gaji \(CurrencyFormatter.format(salary)) " +
                          "sebesar \(CurrencyFormatter.format(excess)). " +
                          "Pastikan penghasilan freelance cukup untuk menutupinya.",
                action:   "Lihat semua pengeluaran",
                category: nil
            )]
        } else if ratio > 0.85 {
            return [SmartAdvice(
                type:     .warning,
                priority: .medium,
                title:    "🟡 Pengeluaran Mendekati Gaji",
                message:  "Pengeluaran sudah \(Int(ratio * 100))% dari gaji pokokmu. " +
                          "Sisa anggaran dari gaji: \(CurrencyFormatter.format(remaining)). " +
                          "Hemat di sisa bulan ya.",
                action:   nil,
                category: nil
            )]
        } else if ratio < 0.5 {
            return [SmartAdvice(
                type:     .positive,
                priority: .low,
                title:    "✅ Keuangan Bulan Ini Sehat!",
                message:  "Pengeluaran baru \(Int(ratio * 100))% dari gaji. " +
                          "Kamu bisa sisihkan \(CurrencyFormatter.format(remaining)) " +
                          "ke tabungan atau investasi.",
                action:   "Tambah tabungan",
                category: nil
            )]
        }
        return []
    }

    private func makeFreelanceAdvice(amount: Decimal) -> SmartAdvice {
        let save    = amount * Decimal(0.5)
        let spend   = amount * Decimal(0.3)
        let invest  = amount * Decimal(0.2)
        return SmartAdvice(
            type:     .tip,
            priority: .medium,
            title:    "💡 Optimasi Penghasilan Freelance",
            message:  "Kamu dapat \(CurrencyFormatter.format(amount)) dari freelance bulan ini. " +
                      "Saran alokasi:\n" +
                      "• Tabungan: \(CurrencyFormatter.format(save)) (50%)\n" +
                      "• Kebutuhan extra: \(CurrencyFormatter.format(spend)) (30%)\n" +
                      "• Investasi/Dana darurat: \(CurrencyFormatter.format(invest)) (20%)",
            action:   nil,
            category: nil
        )
    }

    private func savingsAdvice(income: Decimal, expense: Decimal) -> [SmartAdvice] {
        guard income > 0 else { return [] }
        let savings     = income - expense
        let savingsRate = NSDecimalNumber(decimal: savings / income).doubleValue

        if savings < 0 {
            return [SmartAdvice(
                type:     .alert,
                priority: .high,
                title:    "🚨 Defisit Bulan Ini!",
                message:  "Total pengeluaran melebihi total pemasukan sebesar " +
                          "\(CurrencyFormatter.format(abs(savings))). " +
                          "Segera review dan kurangi pengeluaran tidak penting.",
                action:   "Lihat semua pengeluaran",
                category: nil
            )]
        } else if savingsRate < 0.10 {
            return [SmartAdvice(
                type:     .warning,
                priority: .medium,
                title:    "💸 Tabungan Sangat Minim",
                message:  "Tabungan bulan ini hanya \(Int(savingsRate * 100))% " +
                          "dari pemasukan (\(CurrencyFormatter.format(savings))). " +
                          "Target ideal minimal 20% dari total penghasilan.",
                action:   nil,
                category: nil
            )]
        }
        return []
    }

    private func projectionAdvice(currentExpense: Decimal) -> SmartAdvice? {
        let cal   = Calendar.current
        let today = Date()

        guard cal.component(.month, from: today) == month,
              cal.component(.year,  from: today) == year else { return nil }

        let dayOfMonth  = cal.component(.day, from: today)
        guard dayOfMonth > 5 else { return nil } // Tunggu data minimal 5 hari

        let daysInMonth = cal.range(of: .day, in: .month, for: today)?.count ?? 30
        guard dayOfMonth < daysInMonth else { return nil }

        let dailyAvg       = currentExpense / Decimal(dayOfMonth)
        let projectedTotal = dailyAvg * Decimal(daysInMonth)
        let projRatio      = NSDecimalNumber(decimal: projectedTotal / monthlySalary).doubleValue

        guard projRatio > 0.9 else { return nil }

        let daysLeft = daysInMonth - dayOfMonth
        return SmartAdvice(
            type:     .projection,
            priority: .medium,
            title:    "📈 Proyeksi Pengeluaran Membengkak",
            message:  "Berdasarkan tren \(dayOfMonth) hari terakhir, proyeksi pengeluaran " +
                      "akhir bulan: \(CurrencyFormatter.format(projectedTotal)). " +
                      "Pertimbangkan hemat di \(daysLeft) hari tersisa.",
            action:   nil,
            category: nil
        )
    }

    // MARK: - Category-Specific Tips

    private func specificTip(for categoryName: String, excess: Decimal) -> String {
        let name = categoryName.lowercased()
        if name.contains("makan")       { return "💡 Coba meal prep 2-3x seminggu, bisa hemat Rp 200-400rb/bulan." }
        if name.contains("transport")   { return "💡 Kombinasikan ojol dengan transportasi umum untuk rute rutin." }
        if name.contains("hiburan")     { return "💡 Review langganan streaming yang jarang ditonton." }
        if name.contains("belanja")     { return "💡 Terapkan aturan 24 jam: tunggu sehari sebelum beli barang non-esensial." }
        if name.contains("equipment") ||
           name.contains("kamera")     { return "💡 Pertimbangkan sewa equipment untuk project sekali-kali daripada beli." }
        if name.contains("software") ||
           name.contains("tools")      { return "💡 Cek apakah ada alternatif gratis atau bundled subscription yang lebih murah." }
        return "💡 Review pengeluaran \(categoryName) dan tentukan mana yang bisa dikurangi."
    }
}

// ============================================================
// MARK: - SmartAdvice Model
// Satu item saran yang dihasilkan SmartAdviceEngine.
// ============================================================

struct SmartAdvice: Identifiable {
    let id       = UUID()
    let type:     AdviceType
    let priority: Priority
    let title:    String
    let message:  String
    let action:   String?     // Label tombol aksi (opsional)
    let category: String?     // Nama kategori terkait (opsional)

    // MARK: - AdviceType
    enum AdviceType {
        case overBudget, nearLimit, overspending, warning, positive, tip, alert, projection

        var icon: String {
            switch self {
            case .overBudget:   return "exclamationmark.triangle.fill"
            case .nearLimit:    return "exclamationmark.circle.fill"
            case .overspending: return "xmark.circle.fill"
            case .warning:      return "exclamationmark.circle"
            case .positive:     return "checkmark.circle.fill"
            case .tip:          return "lightbulb.fill"
            case .alert:        return "bell.badge.fill"
            case .projection:   return "chart.line.uptrend.xyaxis"
            }
        }

        var accentColorHex: String {
            switch self {
            case .overBudget, .alert, .overspending: return "#FF6B6B"
            case .nearLimit, .warning, .projection:  return "#F4A261"
            case .positive:                          return "#4CAF82"
            case .tip:                               return "#00C9A7"
            }
        }

        var backgroundColorHex: String {
            switch self {
            case .overBudget, .alert, .overspending: return "#3D1A1A"
            case .nearLimit, .warning, .projection:  return "#3D2D1A"
            case .positive:                          return "#1A3D2D"
            case .tip:                               return "#1A2A3D"
            }
        }
    }

    // MARK: - Priority
    enum Priority: Int, Comparable {
        case low    = 1
        case medium = 2
        case high   = 3

        static func < (lhs: Priority, rhs: Priority) -> Bool { lhs.rawValue < rhs.rawValue }
    }
}
