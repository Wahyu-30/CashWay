import SwiftUI
import FirebaseCore
import GoogleSignIn

// ============================================================
// MARK: - CashWayApp
// Entry point utama aplikasi.
// ============================================================

#if os(iOS)
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
}
#elseif os(macOS)
import AppKit
import Carbon.HIToolbox
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        FirebaseApp.configure()
        // Daftarkan handler URL untuk menangkap callback dari browser setelah Google Sign-In
        NSAppleEventManager.shared().setEventHandler(
            self,
            andSelector: #selector(handleURLEvent(_:replyEvent:)),
            forEventClass: AEEventClass(kInternetEventClass),
            andEventID: AEEventID(kAEGetURL)
        )
    }
    
    @objc func handleURLEvent(_ event: NSAppleEventDescriptor, replyEvent: NSAppleEventDescriptor) {
        guard let urlString = event.paramDescriptor(forKeyword: keyDirectObject)?.stringValue,
              let url = URL(string: urlString) else { return }
        GIDSignIn.sharedInstance.handle(url)
    }
    
    // Backup: handle via application(_:open:) as well
    func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls {
            GIDSignIn.sharedInstance.handle(url)
        }
    }
}
#endif

@main
struct CashWayApp: App {
    #if os(iOS)
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    #elseif os(macOS)
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate
    #endif

    @StateObject private var dataStore = DataStore()
    @StateObject private var authManager = AuthManager()

    var body: some Scene {
        WindowGroup {
            Group {
                if authManager.isAuthenticated {
                    ContentView()
                } else {
                    LoginView()
                }
            }
            .environmentObject(dataStore)
            .environmentObject(authManager)
            .preferredColorScheme(.dark)
            .onOpenURL { url in
                GIDSignIn.sharedInstance.handle(url)
            }
            .onAppear {
                // Seed initial data if empty (after a short delay to allow Firestore listener to populate)
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    if dataStore.categories.isEmpty {
                        dataStore.seedCategories(DefaultData.expenseCategories.enumerated().map {
                            Category(name: $1.name, icon: $1.icon, colorHex: $1.color, type: .expense, isDefault: true, sortOrder: $0)
                        })
                        dataStore.seedCategories(DefaultData.incomeCategories.enumerated().map {
                            Category(name: $1.name, icon: $1.icon, colorHex: $1.color, type: .income, isDefault: true, sortOrder: $0)
                        })
                    }
                    if dataStore.wallets.isEmpty {
                        dataStore.seedWallets(DefaultData.defaultWallets.enumerated().map {
                            Wallet(name: $1.name, type: $1.type, icon: $1.icon, colorHex: $1.color, initialBalance: 0, isDefault: $1.isDefault, sortOrder: $0)
                        })
                    }
                }
            }
        }
        #if os(macOS)
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified)
        .defaultSize(width: 1100, height: 700)
        #endif
    }
}
