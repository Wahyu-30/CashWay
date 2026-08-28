import Foundation
import Observation

// ============================================================
// MARK: - DashboardViewModel
// Business logic untuk halaman Dashboard.
// Dipanggil dari DashboardView via @State private var vm = DashboardViewModel()
// ============================================================

@Observable
@MainActor
final class DashboardViewModel {

    // MARK: - State
    var selectedMonth: Int  = Calendar.current.component(.month, from: .now)
    var selectedYear:  Int  = Calendar.current.component(.year,  from: .now)
    var showAddTransaction: Bool  = false
    var showSmartAdvice:    Bool  = false

    // Data dari @Query di View — di-update via update()
    private var allTransactions: [Transaction] = []
    private var allBudgets:      [Budget]      = []

    var daysUntilExpiration: Int? {
        guard let expiry = ProvisioningInfo.expirationDate() else { return nil }
        let components = Calendar.current.dateComponents([.day], from: Date(), to: expiry)
        return components.day
    }

    // MARK: - Settings
    var monthlySalary: Decimal {
        Decimal(UserDefaults.standard.double(forKey: "monthlySalary"))
    }

    // MARK: - Month Filter
    var monthTransactions: [Transaction] {
        let cal = Calendar.current
        return allTransactions.filter {
            cal.component(.month, from: $0.date) == selectedMonth &&
            cal.component(.year,  from: $0.date) == selectedYear
        }
    }

    // MARK: - Income Breakdown
    var totalIncome: Decimal {
        monthTransactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
    }

    var salaryIncome: Decimal {
        monthTransactions
            .filter { $0.type == .income && $0.incomeTag == .salary }
            .reduce(0) { $0 + $1.amount }
    }

    var freelanceIncome: Decimal {
        monthTransactions
            .filter { $0.type == .income && $0.incomeTag == .business }
            .reduce(0) { $0 + $1.amount }
    }

    var parentsIncome: Decimal {
        monthTransactions
            .filter { $0.type == .income && $0.incomeTag == .parents }
            .reduce(0) { $0 + $1.amount }
    }

    var otherIncome: Decimal {
        monthTransactions
            .filter { $0.type == .income && ($0.incomeTag == .other || $0.incomeTag == nil) }
            .reduce(0) { $0 + $1.amount }
    }

    var totalExpense: Decimal {
        monthTransactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
    }

    var netBalance: Decimal { totalIncome - totalExpense }

    // MARK: - Recent Transactions (5 terakhir)
    var recentTransactions: [Transaction] {
        Array(monthTransactions.sorted { $0.date > $1.date }.prefix(5))
    }

    // MARK: - Daily Expense Chart Data
    // Menghasilkan data (hari, total pengeluaran) untuk bar chart
    var dailyExpenses: [(day: Int, amount: Double)] {
        guard let range = Calendar.current.range(of: .day, in: .month, for: currentMonthDate) else {
            return []
        }
        let cal = Calendar.current
        return range.map { day in
            let total = monthTransactions
                .filter { t in
                    t.type == .expense &&
                    cal.component(.day, from: t.date) == day
                }
                .reduce(Decimal(0)) { $0 + $1.amount }
            return (day: day, amount: NSDecimalNumber(decimal: total).doubleValue)
        }
    }

    var dailyIncome: [(day: Int, amount: Double)] {
        guard let range = Calendar.current.range(of: .day, in: .month, for: currentMonthDate) else {
            return []
        }
        let cal = Calendar.current
        return range.map { day in
            let total = monthTransactions
                .filter { t in
                    t.type == .income &&
                    cal.component(.day, from: t.date) == day
                }
                .reduce(Decimal(0)) { $0 + $1.amount }
            return (day: day, amount: NSDecimalNumber(decimal: total).doubleValue)
        }
    }

    // Apakah total pengeluaran melebihi total pemasukan?
    var isOverspending: Bool {
        totalExpense > totalIncome && totalIncome > 0
    }

    // Persentase pengeluaran terhadap pemasukan
    var spendingRatio: Double {
        guard totalIncome > 0 else { return 0 }
        return NSDecimalNumber(decimal: totalExpense / totalIncome).doubleValue
    }

    // MARK: - Smart Advisory
    var smartAdvices: [SmartAdvice] {
        SmartAdviceEngine(
            // Gunakan salaryIncome aktual dari transaksi. Jika belum ada, gunakan totalIncome.
            // Tidak lagi bergantung pada hardcode 4,5jt di UserDefaults.
            monthlySalary: salaryIncome > 0 ? salaryIncome : (totalIncome > 0 ? totalIncome : 1),
            month: selectedMonth,
            year:  selectedYear
        ).generateAdvice(transactions: allTransactions, budgets: allBudgets)
    }

    var hasHighPriorityAdvice: Bool {
        smartAdvices.contains { $0.priority == .high }
    }

    var adviceBadgeCount: Int {
        smartAdvices.filter { $0.priority == .high }.count
    }

    // MARK: - Month Navigation
    var monthTitle: String {
        let f = DateFormatter()
        f.locale      = Locale(identifier: "id_ID")
        f.dateFormat  = "MMMM yyyy"
        return f.string(from: currentMonthDate)
    }

    var canGoForward: Bool {
        let now = Date()
        let cal = Calendar.current
        return selectedYear  < cal.component(.year,  from: now) ||
              (selectedYear == cal.component(.year,  from: now) &&
               selectedMonth < cal.component(.month, from: now))
    }

    func prevMonth() {
        if selectedMonth == 1 { selectedMonth = 12; selectedYear -= 1 }
        else                  { selectedMonth -= 1 }
    }

    func nextMonth() {
        guard canGoForward else { return }
        if selectedMonth == 12 { selectedMonth = 1; selectedYear += 1 }
        else                   { selectedMonth += 1 }
    }

    // MARK: - Update
    func update(transactions: [Transaction], budgets: [Budget]) {
        allTransactions = transactions
        allBudgets      = budgets
    }

    // MARK: - Private
    private var currentMonthDate: Date {
        Calendar.current.date(from: DateComponents(year: selectedYear, month: selectedMonth)) ?? .now
    }
}
