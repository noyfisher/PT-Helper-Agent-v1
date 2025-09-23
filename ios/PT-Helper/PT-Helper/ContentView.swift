import SwiftUI
import FirebaseAuth

struct ContentView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                Text("You are signed in.")
                Button("Sign out") {
                    try? Auth.auth().signOut()
                }
                .buttonStyle(.bordered)
            }
            .navigationTitle("PT Helper")
            .padding()
        }
    }
}
