import Foundation
import Combine

// ============================================================
// MARK: - ProvisioningInfo
// Helper untuk membaca file profil developer (embedded.mobileprovision).
// Sangat berguna untuk akun Apple Developer Gratis (7 hari expired).
// ============================================================

struct ProvisioningInfo {
    
    /// Membaca kapan aplikasi ini akan expired / tidak bisa dibuka lagi
    /// Mengembalikan nil jika dijalankan di Simulator atau macOS tanpa profil
    static func expirationDate() -> Date? {
        // Cari file sertifikat di dalam bundle aplikasi
        guard let url = Bundle.main.url(forResource: "embedded", withExtension: "mobileprovision"),
              let data = try? Data(contentsOf: url),
              let string = String(data: data, encoding: .isoLatin1) else {
            return nil
        }
        
        // Ekstrak bagian XML (karena file ini adalah format biner PKCS7 dengan XML di dalamnya)
        guard let start = string.range(of: "<?xml"),
              let end = string.range(of: "</plist>") else {
            return nil
        }
        
        let plistString = String(string[start.lowerBound...end.upperBound])
        guard let plistData = plistString.data(using: .utf8) else {
            return nil
        }
        
        // Parse XML menjadi Dictionary untuk mengambil 'ExpirationDate'
        do {
            if let plist = try PropertyListSerialization.propertyList(from: plistData, options: [], format: nil) as? [String: Any] {
                return plist["ExpirationDate"] as? Date
            }
        } catch {
            print("Error parsing provisioning profile: \(error)")
        }
        
        return nil
    }
}
