import SwiftUI
import SwiftData

// ============================================================
// MARK: - CashWayApp
// Entry point utama aplikasi. Setup ModelContainer di sini.
// Jangan ubah init() kecuali perlu tambah Model baru.
// ============================================================

@main
struct CashWayApp: App {

    let modelContainer: ModelContainer

    init() {
        // Daftarkan semua SwiftData Model di sini
        let schema = Schema([
            Transaction.self,
            Category.self,
            Wallet.self,
            Budget.self,
            SavingsGoal.self,
        ])

        // Konfigurasi penyimpanan
        // cloudKitDatabase: .none → offline only (default)
        // cloudKitDatabase: .automatic → aktifkan iCloud sync (ubah dari Settings)
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .none
        )

        do {
            modelContainer = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("❌ Gagal inisialisasi database: \(error.localizedDescription)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(modelContainer)
                .preferredColorScheme(.dark)          // Default dark mode
                .onAppear {
                    // Seed data kategori & wallet default saat pertama kali buka
                    DefaultData.seedIfNeeded(context: modelContainer.mainContext)
                }
        }
        #if os(macOS)
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified)
        .defaultSize(width: 1100, height: 700)
        #endif
    }
}
