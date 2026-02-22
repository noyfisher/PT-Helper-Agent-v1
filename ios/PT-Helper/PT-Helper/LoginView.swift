import SwiftUI
import AuthenticationServices
import CryptoKit
import FirebaseAuth
import FirebaseFirestore

struct LoginView: View {
    var onSignedIn: () -> Void
    @StateObject private var vm = LoginVM()
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 20) {
            Text("Welcome to PT Helper").font(.title2)

            SignInWithAppleButton(.signIn) { req in
                vm.prepare(req)                   // add scopes + nonce
            } onCompletion: { result in
                vm.handle(result) { onSignedIn() } // sign into Firebase
            }
            .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
            .frame(height: 50)
            .padding(.horizontal, 32)

            if let msg = vm.msg {
                Text(msg).font(.footnote).foregroundColor(.secondary)
            }
        }
        .padding()
    }
}

final class LoginVM: NSObject, ObservableObject {
    @Published var msg: String?
    private var nonce: String?

    func prepare(_ req: ASAuthorizationAppleIDRequest) {
        let n = randomNonce()
        nonce = n
        req.requestedScopes = [.fullName, .email]
        req.nonce = sha256(n)
        msg = "Preparing sign in…"
    }

    func handle(_ result: Result<ASAuthorization, Error>, onSuccess: @escaping () -> Void) {
        switch result {
        case .failure(let e):
            msg = "Apple error: \(e.localizedDescription)"

        case .success(let auth):
            guard
                let cred = auth.credential as? ASAuthorizationAppleIDCredential,
                let tokenData = cred.identityToken,
                let idToken = String(data: tokenData, encoding: .utf8),
                let nonce
            else { msg = "Missing Apple token/nonce"; return }

            let fcred = OAuthProvider.appleCredential(withIDToken: idToken,
                                                      rawNonce: nonce,
                                                      fullName: cred.fullName) // fullName is optional; helps store display name on first sign-in


            Auth.auth().signIn(with: fcred) { res, err in
                if let err = err { self.msg = "Firebase error: \(err.localizedDescription)"; return }
                self.msg = "Signed in ✅"

                if let uid = res?.user.uid {
                    self.ensureUser(uid: uid,
                                    name: cred.fullName?.givenName ?? res?.user.displayName ?? "User")
                }
                onSuccess()
            }
        }
    }

    private func ensureUser(uid: String, name: String) {
        let db = Firestore.firestore()
        let ref = db.collection("users").document(uid)
        ref.getDocument { snap, _ in
            guard snap?.exists != true else { return }
            ref.setData([
                "name": name,
                "role": "athlete",                 // you can add a role picker later
                "created_at": FieldValue.serverTimestamp()
            ])
        }
    }

    // MARK: - nonce helpers
    private func randomNonce(length: Int = 32) -> String {
        let chars = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var out = ""; var left = length
        while left > 0 {
            var bytes = [UInt8](repeating: 0, count: 16)
            _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
            for b in bytes where left > 0 {
                if b < chars.count { out.append(chars[Int(b)]); left -= 1 }
            }
        }
        return out
    }

    private func sha256(_ s: String) -> String {
        let h = SHA256.hash(data: Data(s.utf8))
        return h.map { String(format: "%02x", $0) }.joined()
    }
}
