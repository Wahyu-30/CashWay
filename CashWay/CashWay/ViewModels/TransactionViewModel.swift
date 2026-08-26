import Foundation
import Observation

// ============================================================
// MARK: - TransactionViewModel
// Business logic untuk Add/Edit/Delete transaksi.
// Dipakai di AddTransactionView dan TransactionListView.
// ============================================================

@Observable
@MainActor
final class TransactionViewModel {

    // MARK: - Form State (untuk AddTransactionView)
    var amountText:    String                       = ""
    var selectedType:  Transaction.TransactionType  = .expense
    var selectedCategory: Category?                 = nil
    var selectedWallet:   Wallet?                   = nil
    var selectedDate:     Date                      = .now
    var note:             String                    = ""
    var selectedIncomeTag: Transaction.IncomeTag    = .salary

    // MARK: - List State (untuk TransactionListView)
    var searchText:       String                           = ""
    var filterType:       Transaction.TransactionType?     = nil
    var filterCategory:   Category?                        = nil
    var showAddSheet:     Bool                             = false
    var editingTransaction: Transaction?                   = nil
    var deletingTransaction: Transaction?                  = nil

    // MARK: - Computed: Amount dari text input
    var amount: Decimal {
        CurrencyFormatter.parse(amountText)
    }

    var isValidForm: Bool {
        amount > 0 && selectedCategory != nil && selectedWallet != nil
    }

    // MARK: - Filter Transactions
    func filtered(_ transactions: [Transaction]) -> [Transaction] {
        transactions
            .filter { filterType == nil || $0.type == filterType }
            .filter { filterCategory == nil || $0.category?.id == filterCategory?.id }
            .filter {
                searchText.isEmpty ||
                ($0.note.localizedCaseInsensitiveContains(searchText)) ||
                ($0.category?.name.localizedCaseInsensitiveContains(searchText) == true)
            }
            .sorted { $0.date > $1.date }
    }

    // Group transaksi by date (untuk tampilan di list)
    func grouped(_ transactions: [Transaction]) -> [(date: Date, items: [Transaction])] {
        let filtered = filtered(transactions)
        let calendar = Calendar.current
        let groups   = Dictionary(grouping: filtered) {
            calendar.startOfDay(for: $0.date)
        }
        return groups
            .map { (date: $0.key, items: $0.value.sorted { $0.date > $1.date }) }
            .sorted { $0.date > $1.date }
    }

    // MARK: - CRUD Operations

    /// Simpan transaksi baru atau update yang sudah ada
    func save(dataStore: DataStore) {
        guard isValidForm else { return }

        if var existing = editingTransaction {
            // Update
            existing.amount   = amount
            existing.type     = selectedType
            existing.category = selectedCategory
            existing.wallet   = selectedWallet
            existing.date     = selectedDate
            existing.note     = note
            existing.incomeTag = selectedType == .income ? selectedIncomeTag : nil
            dataStore.addTransaction(existing)
        } else {
            // Insert baru
            let transaction = Transaction(
                amount:    amount,
                type:      selectedType,
                date:      selectedDate,
                note:      note,
                category:  selectedCategory,
                wallet:    selectedWallet,
                incomeTag: selectedType == .income ? selectedIncomeTag : nil
            )
            dataStore.addTransaction(transaction)
        }

        resetForm()
    }

    /// Hapus transaksi
    func delete(_ transaction: Transaction, dataStore: DataStore) {
        dataStore.deleteTransaction(transaction)
    }

    // MARK: - Form Helpers

    /// Reset form ke state awal
    func resetForm() {
        amountText        = ""
        selectedType      = .expense
        selectedCategory  = nil
        selectedDate      = .now
        note              = ""
        selectedIncomeTag = .salary
        editingTransaction = nil
    }

    /// Load data transaksi ke form untuk edit
    func loadForEdit(_ transaction: Transaction) {
        editingTransaction  = transaction
        amountText          = String(describing: transaction.amount)
        selectedType        = transaction.type
        selectedCategory    = transaction.category
        selectedWallet      = transaction.wallet
        selectedDate        = transaction.date
        note                = transaction.note
        selectedIncomeTag   = transaction.incomeTag ?? .salary
    }

    /// Format amount text saat user input (auto-format Rupiah)
    func formatAmountInput(_ newValue: String) {
        let digits = newValue.filter { $0.isNumber }
        let decimal = Decimal(string: digits) ?? 0
        amountText = digits.isEmpty ? "" : digits
        _ = decimal // gunakan untuk validasi jika perlu
    }
}
