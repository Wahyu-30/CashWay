import Foundation
import Combine
import FirebaseAuth
import FirebaseCore
import GoogleSignIn
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

// ============================================================
// MARK: - AuthManager
// Mengelola status autentikasi pengguna dan integrasi Google Sign-In.
// ============================================================

class AuthManager: ObservableObject {
    
    @Published var user: FirebaseAuth.User?
    @Published var isAuthenticating: Bool = false
    @Published var errorMessage: String?
    
    init() {
        self.user = Auth.auth().currentUser
        
        // Listener otomatis jika status login berubah (misal token expired, dsb)
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                self?.user = user
            }
        }
    }
    
    var isAuthenticated: Bool {
        return user != nil
    }
    
    // MARK: - Google Sign-In
    
    func signInWithGoogle() {
        isAuthenticating = true
        errorMessage = nil
        
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            self.errorMessage = "Konfigurasi Firebase belum siap."
            self.isAuthenticating = false
            return
        }
        
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        #if os(iOS)
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            self.errorMessage = "Tidak dapat menemukan tampilan utama aplikasi."
            self.isAuthenticating = false
            return
        }
        let presenting = rootViewController
        #elseif os(macOS)
        guard let presenting = NSApplication.shared.windows.first else {
            self.errorMessage = "Tidak dapat menemukan jendela utama."
            self.isAuthenticating = false
            return
        }
        #endif
        
        // Mulai proses Google Sign-In
        GIDSignIn.sharedInstance.signIn(withPresenting: presenting) { [weak self] signInResult, error in
            if let error = error {
                DispatchQueue.main.async {
                    // Tampilkan SEMUA error beserta kode error untuk debugging
                    let nsErr = error as NSError
                    self?.errorMessage = "Error [\(nsErr.domain) \(nsErr.code)]: \(error.localizedDescription)"
                    self?.isAuthenticating = false
                }
                return
            }
            
            guard let signInResult = signInResult,
                  let idToken = signInResult.user.idToken?.tokenString else {
                DispatchQueue.main.async {
                    self?.errorMessage = "Token Google tidak valid."
                    self?.isAuthenticating = false
                }
                return
            }
            
            let accessToken = signInResult.user.accessToken.tokenString
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
            
            Auth.auth().signIn(with: credential) { authResult, error in
                DispatchQueue.main.async {
                    self?.isAuthenticating = false
                    if let error = error {
                        self?.errorMessage = "Gagal masuk ke Firebase: \(error.localizedDescription)"
                        return
                    }
                }
            }
        }
    }
    
    // MARK: - Sign Out
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            GIDSignIn.sharedInstance.signOut()
        } catch let signOutError as NSError {
            self.errorMessage = "Gagal keluar: \(signOutError.localizedDescription)"
        }
    }
}
