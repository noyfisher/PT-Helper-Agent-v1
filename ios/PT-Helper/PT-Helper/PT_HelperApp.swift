import SwiftUI
import FirebaseCore

@main
struct PainPointApp: App {
    init() {
        FirebaseApp.configure()   // uses GoogleService-Info.plist in this target
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}
