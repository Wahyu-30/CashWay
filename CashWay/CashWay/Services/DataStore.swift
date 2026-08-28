import Combine

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

// ============================================================
// MARK: - DataStore
// Mengelola semua data dengan isolasi per pengguna (userId).
// Setiap query difilter berdasarkan UID Google pengguna aktif.
// ============================================================

@MainActor
class DataStore: ObservableObject {
    @Published var transactions: [Transaction] = []
    @Published var categories: [Category] = []
    @Published var wallets: [Wallet] = []
    @Published var budgets: [Budget] = []
    @Published var savingsGoals: [SavingsGoal] = []
    
    private var db: Firestore { FirebaseManager.shared.db }
    
    // Ambil UID pengguna yang sedang login. Jika tidak ada, return nil.
    private var currentUserId: String? {
        Auth.auth().currentUser?.uid
    }
    
    init() {
        // Init empty — data dimuat via startListening()
    }
    
    func startListening() {
        guard currentUserId != nil else {
            print("DataStore: Tidak ada pengguna yang login, skip fetching.")
            return
        }
        fetchCategories()
        fetchWallets()
        fetchTransactions()
        fetchBudgets()
        fetchSavingsGoals()
    }
    
    // Hapus semua data dari layar saat pengguna logout
    func clearData() {
        transactions = []
        categories = []
        wallets = []
        budgets = []
        savingsGoals = []
    }
    
    // MARK: - Generic Fetcher (tanpa order di Firestore — hindari composite index)
    private func fetchCollection<T: Codable>(collection: String, completion: @escaping ([T]) -> Void) {
        guard let uid = currentUserId else { return }
        db.collection(collection)
            .whereField("userId", isEqualTo: uid)
            .addSnapshotListener { snapshot, error in
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
    
    // MARK: - Fetchers (sorting dilakukan di sisi client)
    private func fetchCategories() {
        fetchCollection(collection: "categories") { [weak self] (items: [Category]) in
            self?.categories = items.sorted { $0.sortOrder < $1.sortOrder }
        }
    }
    
    private func fetchWallets() {
        fetchCollection(collection: "wallets") { [weak self] (items: [Wallet]) in
            self?.wallets = items.sorted { $0.sortOrder < $1.sortOrder }
        }
    }
    
    private func fetchTransactions() {
        guard let uid = currentUserId else { return }
        db.collection("transactions")
            .whereField("userId", isEqualTo: uid)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let documents = snapshot?.documents else { return }
                let items: [Transaction] = documents
                    .compactMap { try? $0.data(as: Transaction.self) }
                    .sorted { $0.date > $1.date }
                self?.transactions = items
                self?.recalculateBudgets(transactions: items)
            }
    }
    
    private func fetchBudgets() {
        fetchCollection(collection: "budgets") { [weak self] (items: [Budget]) in
            guard let self = self else { return }
            self.budgets = items.sorted { $0.month < $1.month }
            self.recalculateBudgets(transactions: self.transactions)
        }
    }
    
    private func fetchSavingsGoals() {
        fetchCollection(collection: "savingsGoals") { [weak self] (items: [SavingsGoal]) in
            self?.savingsGoals = items.sorted { $0.createdAt < $1.createdAt }
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
    
    // MARK: - Public Write APIs (userId otomatis disuntikkan)
    
    func addTransaction(_ tx: Transaction) {
        guard let uid = currentUserId else { return }
        var stamped = tx
        stamped.userId = uid
        saveDocument(collection: "transactions", id: stamped.id, data: stamped)
    }
    func deleteTransaction(_ tx: Transaction) { deleteDocument(collection: "transactions", id: tx.id) }
    
    func addBudget(_ b: Budget) {
        guard let uid = currentUserId else { return }
        var stamped = b
        stamped.userId = uid
        saveDocument(collection: "budgets", id: stamped.id, data: stamped)
    }
    func deleteBudget(_ b: Budget) { deleteDocument(collection: "budgets", id: b.id) }
    
    func addSavingsGoal(_ s: SavingsGoal) {
        guard let uid = currentUserId else { return }
        var stamped = s
        stamped.userId = uid
        saveDocument(collection: "savingsGoals", id: stamped.id, data: stamped)
    }
    func updateSavingsGoal(_ s: SavingsGoal) {
        guard let uid = currentUserId else { return }
        var stamped = s
        stamped.userId = uid
        saveDocument(collection: "savingsGoals", id: stamped.id, data: stamped)
    }
    func deleteSavingsGoal(_ s: SavingsGoal) { deleteDocument(collection: "savingsGoals", id: s.id) }
    
    // Seed data default — otomatis di-stempel dengan userId
    func seedCategories(_ items: [Category]) {
        guard let uid = currentUserId else { return }
        for item in items {
            var stamped = item
            stamped.userId = uid
            saveDocument(collection: "categories", id: stamped.id, data: stamped)
        }
    }
    func seedWallets(_ items: [Wallet]) {
        guard let uid = currentUserId else { return }
        for item in items {
            var stamped = item
            stamped.userId = uid
            saveDocument(collection: "wallets", id: stamped.id, data: stamped)
        }
    }
}
