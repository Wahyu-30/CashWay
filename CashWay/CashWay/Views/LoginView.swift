import SwiftUI
import GoogleSignInSwift

// ============================================================
// MARK: - LoginView
// Halaman login pertama kali saat aplikasi dibuka.
// ============================================================

struct LoginView: View {
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        ZStack {
            Color.cwBackground.ignoresSafeArea()
            
            VStack(spacing: CWSpacing.xl) {
                Spacer()
                
                // Logo & Header
                VStack(spacing: CWSpacing.md) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 24)
                            .fill(
                                LinearGradient(
                                    colors: [Color.cwAccent, Color(hex: "#9019e6")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 96, height: 96)
                        Image(systemName: "coloncurrencysign.arrow.trianglehead.counterclockwise.rotate.90")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    .shadow(color: Color.cwAccent.opacity(0.3), radius: 12, y: 8)
                    
                    Text("CashWay")
                        .font(.system(size: 36, weight: .black, design: .rounded))
                        .foregroundStyle(Color.cwTextPrimary)
                    
                    Text("Lacak keuanganmu, amankan masa depanmu.")
                        .font(.subheadline)
                        .foregroundStyle(Color.cwTextSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                
                Spacer()
                
                // Error Message
                if let error = authManager.errorMessage {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(Color.cwExpense)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                // Google Sign In Button
                VStack(spacing: CWSpacing.md) {
                    if authManager.isAuthenticating {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .scaleEffect(1.5)
                            .tint(Color.cwAccent)
                    } else {
                        Button(action: {
                            authManager.signInWithGoogle()
                        }) {
                            HStack(spacing: 12) {
                                // Google Icon
                                Image(systemName: "g.circle.fill")
                                    .font(.title2)
                                Text("Lanjutkan dengan Google")
                                    .font(.headline.weight(.semibold))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.white)
                            .foregroundStyle(.black)
                            .clipShape(RoundedRectangle(cornerRadius: CWRadius.md))
                            .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
                        }
                    }
                    
                    Text("Dengan login, kamu menyetujui penyimpanan data di server cloud pribadimu sendiri secara aman.")
                        .font(.caption2)
                        .foregroundStyle(Color.cwTextSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, CWSpacing.lg)
                .padding(.bottom, CWSpacing.xl)
            }
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthManager())
        .preferredColorScheme(.dark)
}
