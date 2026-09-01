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
    
    // Simpan semua listener aktif agar bisa dimatikan saat logout
    private var listeners: [ListenerRegistration] = []
    
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
        // onAppear dan perubahan status auth dapat sama-sama memanggil method ini.
        // Hentikan listener lama agar satu akun hanya memiliki satu listener per koleksi.
        stopListening()
        fetchCategories()
        fetchWallets()
        fetchTransactions()
        fetchBudgets()
        fetchSavingsGoals()
    }
    
    // Matikan SEMUA listener aktif dan hapus data dari layar saat logout
    func clearData() {
        stopListening()
        
        transactions = []
        categories = []
        wallets = []
        budgets = []
        savingsGoals = []
    }

    private func stopListening() {
        listeners.forEach { $0.remove() }
        listeners.removeAll()
    }
    
    // MARK: - Generic Fetcher (tanpa order di Firestore — hindari composite index)
    private func fetchCollection<T: Decodable>(collection: String, completion: @escaping ([T]) -> Void) {
        guard let uid = currentUserId else { return }
        let listener = db.collection(collection)
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
        listeners.append(listener)
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
        let listener = db.collection("transactions")
            .whereField("userId", isEqualTo: uid)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let documents = snapshot?.documents else { return }
                let items: [Transaction] = documents
                    .compactMap { try? $0.data(as: Transaction.self) }
                    .sorted { $0.date > $1.date }
                self?.transactions = items
                self?.recalculateBudgets(transactions: items)
            }
        listeners.append(listener)
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
            let catIds = Set(budget.allCategoryIds)
            // Jika tidak ada category ID sama sekali, skip
            guard !catIds.isEmpty else { budgets[i].spent = 0; continue }
            let spent = transactions.filter { tx in
                guard tx.type == .expense, let catId = tx.category?.id else { return false }
                let m = cal.component(.month, from: tx.date)
                let y = cal.component(.year, from: tx.date)
                return m == budget.month && y == budget.year && catIds.contains(catId)
            }.reduce(0) { $0 + $1.amount }
            budgets[i].spent = spent
        }
    }
    
    // MARK: - Writers
    private func saveDocument<T: Encodable>(collection: String, id: String, data: T) {
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

    // MARK: - Deduplication + Restore
    /// Membersihkan hanya data milik pengguna aktif. Kategori dibedakan oleh
    /// nama + tipe agar kategori "Lainnya" untuk pemasukan dan pengeluaran tidak
    /// saling terhapus. Dokumen pengguna lain maupun dokumen lama tanpa userId
    /// tidak pernah disentuh.
    func cleanupDuplicates() async -> Int {
        guard let uid = currentUserId else { return 0 }

        do {
            let categories = try await db.collection("categories")
                .whereField("userId", isEqualTo: uid)
                .getDocuments()
            let wallets = try await db.collection("wallets")
                .whereField("userId", isEqualTo: uid)
                .getDocuments()

            let categoryDuplicates = duplicateDocuments(
                in: categories.documents,
                key: { document in
                    let data = document.data()
                    let name = data["name"] as? String ?? document.documentID
                    let type = data["type"] as? String ?? ""
                    return "\(type)|\(name)"
                }
            )
            let walletDuplicates = duplicateDocuments(
                in: wallets.documents,
                key: { document in
                    document.data()["name"] as? String ?? document.documentID
                }
            )

            let existingWalletNames = Set(wallets.documents.compactMap {
                $0.data()["name"] as? String
            })

            let missingDefaultWallets = DefaultData.defaultWallets.enumerated().filter {
                !existingWalletNames.contains($0.element.name)
            }

            let batch = db.batch()
            for document in categoryDuplicates + walletDuplicates {
                batch.deleteDocument(document.reference)
            }

            // Restorasi hanya jika wallet default benar-benar tidak ada. ID yang
            // deterministik membuat operasi aman bila pengguna menekan tombol lagi.
            for (index, item) in missingDefaultWallets {
                let wallet = Wallet(
                    id: defaultDocumentID(userId: uid, kind: "wallet", index: index),
                    userId: uid,
                    name: item.name,
                    type: item.type,
                    icon: item.icon,
                    colorHex: item.color,
                    initialBalance: 0,
                    isDefault: item.isDefault,
                    sortOrder: index
                )
                try batch.setData(from: wallet, forDocument: db.collection("wallets").document(wallet.id))
            }

            // Tidak kirim write kosong; ini menghindari perubahan database saat
            // tidak ada duplikat atau wallet yang hilang.
            if !categoryDuplicates.isEmpty || !walletDuplicates.isEmpty ||
                !missingDefaultWallets.isEmpty {
                try await batch.commit()
            }

            return categoryDuplicates.count + walletDuplicates.count
        } catch {
            print("DataStore: Gagal membersihkan data duplikat — \(error.localizedDescription)")
            return 0
        }
    }

    private func duplicateDocuments(
        in documents: [QueryDocumentSnapshot],
        key: (QueryDocumentSnapshot) -> String
    ) -> [QueryDocumentSnapshot] {
        let grouped = Dictionary(grouping: documents, by: key)
        return grouped.values.flatMap { group in
            // ID dokumen dipakai sebagai tie-breaker sehingga data yang dipertahankan
            // selalu konsisten dan tidak bergantung urutan respons Firestore.
            group.sorted { $0.documentID < $1.documentID }.dropFirst()
        }
    }

    private func defaultDocumentID(userId: String, kind: String, index: Int) -> String {
        "\(userId)_default_\(kind)_\(index)"
    }
}
