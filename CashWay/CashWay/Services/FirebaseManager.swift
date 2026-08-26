import Foundation
import FirebaseCore
import FirebaseFirestore

class FirebaseManager {
    static let shared = FirebaseManager()
    
    var db: Firestore {
        return Firestore.firestore()
    }
    
    private init() {
        // Do nothing here! App delegate handles FirebaseApp.configure()
    }
}
