import Combine

import SwiftUI
import FirebaseFirestore

@MainActor
class DataStore: ObservableObject {
    @Published var transactions: [Transaction] = []
    @Published var categories: [Category] = []
    @Published var wallets: [Wallet] = []
    @Published var budgets: [Budget] = []
    @Published var savingsGoals: [SavingsGoal] = []
    
    private let db = FirebaseManager.shared.db
    
    init() {
        // Fetch all data
        fetchCategories()
        fetchWallets()
        fetchTransactions()
        fetchBudgets()
        fetchSavingsGoals()
    }
    
    // MARK: - Generic Fetcher
    private func fetchCollection<T: Codable>(collection: String, sortField: String, completion: @escaping ([T]) -> Void) {
        db.collection(collection).order(by: sortField, descending: false).addSnapshotListener { snapshot, error in
            guard let documents = snapshot?.documents else {
                print("Error fetching \(collection): \(error?.localizedDescription ?? "Unknown")")
                return
            }
            let items: [T] = documents.compactMap { doc in
                try? doc.data(as: T.self)
            }
            completion(items)
        }
    }
    
    // MARK: - Fetchers
    private func fetchCategories() {
        fetchCollection(collection: "categories", sortField: "sortOrder") { [weak self] items in
            self?.categories = items
        }
    }
    
    private func fetchWallets() {
        fetchCollection(collection: "wallets", sortField: "sortOrder") { [weak self] items in
            self?.wallets = items
        }
    }
    
    private func fetchTransactions() {
        db.collection("transactions").order(by: "date", descending: true).addSnapshotListener { [weak self] snapshot, error in
            guard let documents = snapshot?.documents else { return }
            let items: [Transaction] = documents.compactMap { try? $0.data(as: Transaction.self) }
            self?.transactions = items
            
            // Recalculate budgets spent amount
            self?.recalculateBudgets(transactions: items)
        }
    }
    
    private func fetchBudgets() {
        fetchCollection(collection: "budgets", sortField: "month") { [weak self] items in
            guard let self = self else { return }
            self.budgets = items
            self.recalculateBudgets(transactions: self.transactions)
        }
    }
    
    private func fetchSavingsGoals() {
        fetchCollection(collection: "savingsGoals", sortField: "createdAt") { [weak self] items in
            self?.savingsGoals = items
        }
    }
    
    // MARK: - Helpers
    private func recalculateBudgets(transactions: [Transaction]) {
        let cal = Calendar.current
        for i in 0..<budgets.count {
            let budget = budgets[i]
            let spent = transactions.filter { tx in
                guard tx.type == .expense, let catId = tx.category?.id else { return false }
                let m = cal.component(.month, from: tx.date)
                let y = cal.component(.year, from: tx.date)
                return m == budget.month && y == budget.year && catId == budget.category?.id
            }.reduce(0) { $0 + $1.amount }
            budgets[i].spent = spent
        }
    }
    
    // MARK: - Writers
    private func saveDocument<T: Codable>(collection: String, id: String, data: T) {
        do {
            try db.collection(collection).document(id).setData(from: data)
        } catch {
            print("Error saving to \(collection): \(error)")
        }
    }
    
    private func deleteDocument(collection: String, id: String) {
        db.collection(collection).document(id).delete()
    }
    
    // Transactions
    func addTransaction(_ tx: Transaction) { saveDocument(collection: "transactions", id: tx.id, data: tx) }
    func deleteTransaction(_ tx: Transaction) { deleteDocument(collection: "transactions", id: tx.id) }
    
    // Budgets
    func addBudget(_ b: Budget) { saveDocument(collection: "budgets", id: b.id, data: b) }
    func deleteBudget(_ b: Budget) { deleteDocument(collection: "budgets", id: b.id) }
    
    // Savings
    func addSavingsGoal(_ s: SavingsGoal) { saveDocument(collection: "savingsGoals", id: s.id, data: s) }
    func updateSavingsGoal(_ s: SavingsGoal) { saveDocument(collection: "savingsGoals", id: s.id, data: s) }
    func deleteSavingsGoal(_ s: SavingsGoal) { deleteDocument(collection: "savingsGoals", id: s.id) }
    
    // Seed helper
    func seedCategories(_ items: [Category]) { for item in items { saveDocument(collection: "categories", id: item.id, data: item) } }
    func seedWallets(_ items: [Wallet]) { for item in items { saveDocument(collection: "wallets", id: item.id, data: item) } }
}
