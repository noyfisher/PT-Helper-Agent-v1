import SwiftUI
import FirebaseAuth

struct RootView: View {
    @State private var signedIn = (Auth.auth().currentUser != nil)

    var body: some View {
        Group {
            if signedIn {
                ContentView()
            } else {
                LoginView(onSignedIn: { signedIn = true })
            }
        }
        .onAppear {
            Auth.auth().addStateDidChangeListener { _, user in
                signedIn = (user != nil)
            }
        }
    }
}

