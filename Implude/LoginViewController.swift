import UIKit
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift
import GoogleSignIn

class LoginViewController: UIViewController, GIDSignInDelegate {
    var user: User = User(email: "", name: "")

    override func viewDidLoad() {
        super.viewDidLoad()

        GIDSignIn.sharedInstance().delegate = self
        GIDSignIn.sharedInstance().presentingViewController = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
    }

    func sign(_ signIn: GIDSignIn!, didSignInFor googleUser: GIDGoogleUser!, withError error: Error!) {
        if let error = error {
            showErrorAlert(error: error)
            return
        }

        let email: String = googleUser.profile.email
        user.email = email

        getUserInfoIfValid(email: email) {
            guard let authentication = googleUser.authentication else { return }
            guard !self.user.name.isEmpty else {
                self.showErrorAlert(message: "Implude 동아리 부원으로 추가되지 않은 계정입니다.")
                return
            }
            let credential = GoogleAuthProvider.credential(withIDToken: authentication.idToken, accessToken: authentication.accessToken)
            Auth.auth().signIn(with: credential, completion: self.onSignComplete)
        }
    }

    private func getUserInfoIfValid(email: String, _ onResult: @escaping () -> Void) {
        Firestore.firestore().collection("emails").document(email).getDocument { (document, error) in
            guard let document = document, document.exists else {
                onResult()
                return
            }
            let data = document.data()
            self.user.name = data?["name"] as? String ?? ""
            self.user.admin = data?["admin"] as? Bool ?? false
            onResult()
        }
    }

    private func onSignComplete(authResult: AuthDataResult!, error: Error?) {
        if let error = error {
            showErrorAlert(error: error)
            return
        }

        user.uid = authResult.user.uid
        saveUserToDatabase()
    }

    private func saveUserToDatabase() {
        let data: [String: Any] = [
            "email": user.email,
            "name": user.name,
            "admin": user.admin,
            "profile": user.profile
        ]
        Firestore.firestore().collection("users").document(user.uid).setData(data)
    }

    private func showErrorAlert(error: Error? = nil, message: String = "오류가 발생했습니다. 다시 시도해 주세요.") {
        print(error?.localizedDescription ?? "Error")
        let alert = UIAlertController(title: "오류", message: message, preferredStyle: .alert)
        present(alert, animated: true)
    }
}
