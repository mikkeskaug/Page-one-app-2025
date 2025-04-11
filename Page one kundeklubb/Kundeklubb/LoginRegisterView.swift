import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import CoreImage.CIFilterBuiltins

struct LoginRegisterView: View {
    @Binding var isSignedIn: Bool
    @Binding var userName: String
    @Binding var userEmail: String
    @Binding var qrCode: UIImage?
    @Binding var userImage: UIImage?  // ✅ Pass user image

    @State private var email = ""
    @State private var password = ""
    @State private var fullName = ""
    @State private var isRegistering = false
    @State private var errorMessage: String?  // ✅ Error message state
    
    @EnvironmentObject var userManager: UserManager  // ✅ Access user data


    var body: some View {
        VStack {
            Text(isRegistering ? "Registrer" : "Logg inn")
                .font(.title)
                .fontWeight(.bold)
                .padding()

            if isRegistering {
                TextField("Navn", text: $fullName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
            }

            TextField("E-post", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            SecureField("Passord", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            // ❌ Show Error Message if Login Fails
            if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.callout)
                    .padding()
                    .multilineTextAlignment(.center)
            }

            if isRegistering {
                Button("Registrer") {
                    registerUser()
                }
                .frame(height: 50)
                .frame(maxWidth: .infinity)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                .padding()
            } else {
                Button("Logg inn") {
                    loginUser()
                }
                .frame(height: 50)
                .frame(maxWidth: .infinity)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                .padding()
            }

            Button(isRegistering ? "Har du allerede en konto? Logg inn" : "Lag ny konto") {
                isRegistering.toggle()
            }
            .padding()

            if !isRegistering {
                Button("Glemt passord?") {
                    resetPassword()
                }
                .foregroundColor(.blue)
                .padding()
            }

            if let qr = qrCode {
                Text("Your QR Code")
                    .font(.headline)
                    .padding(.top, 10)

                Image(uiImage: qr)
                    .resizable()
                    .interpolation(.none)
                    .scaledToFit()
                    .frame(width: 150, height: 150)
                    .padding(.top, 10)
            }
        }
        .padding()
    }

    func loginUser() {
        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            if let error = error {
                print("❌ Login Error: \(error.localizedDescription)")
                self.errorMessage = error.localizedDescription  // ✅ Display error message
                return
            }

            print("✅ Login successful")
            fetchUserData()  // ✅ Fetch user data after login
        }
    }

    func fetchUserData() {
        if let user = Auth.auth().currentUser {
            let db = Firestore.firestore()
            let docRef = db.collection("users").document(user.email ?? "")

            docRef.getDocument { (document, error) in
                if let document = document, document.exists {
                    let fetchedName = document.data()?["name"] as? String ?? "User"
                    let fetchedEmail = user.email ?? ""
                    let fetchedPhoneNumber = document.data()?["phoneNumber"] as? String ?? ""
                    let fetchedPostcode = document.data()?["postcode"] as? String ?? ""
                    let fetchedPostPlace = document.data()?["postPlace"] as? String ?? ""

                    DispatchQueue.main.async {
                        self.userName = fetchedName
                        self.userEmail = fetchedEmail
                        self.qrCode = self.generateQRCode(from: fetchedEmail)
                        self.isSignedIn = true

                        // ✅ Update the global UserManager
                        if let userManager = UIApplication.shared.connectedScenes
                            .compactMap({ ($0 as? UIWindowScene)?.windows.first?.rootViewController as? UIHostingController<ContentView> })
                            .first?.rootView.environmentObject(UserManager()) {

                            self.userManager.name = fetchedName
                            self.userManager.email = fetchedEmail
                            self.userManager.phoneNumber = fetchedPhoneNumber
                            self.userManager.postcode = fetchedPostcode
                            self.userManager.postPlace = fetchedPostPlace
                        }

                        // ✅ Fetch user profile image
                        if let imageURLString = document.data()?["profileImageURL"] as? String,
                           let url = URL(string: imageURLString) {
                            DispatchQueue.global().async {
                                if let imageData = try? Data(contentsOf: url),
                                   let uiImage = UIImage(data: imageData) {
                                    DispatchQueue.main.async {
                                        self.userImage = uiImage
                                    }
                                }
                            }
                        }
                    }
                } else {
                    self.errorMessage = "Brukerdata ikke funnet."
                }
            }
        }
    }
    func registerUser() {
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let error = error {
                print("❌ Registration Error: \(error.localizedDescription)")
                self.errorMessage = error.localizedDescription
                return
            }

            guard let user = authResult?.user else { return }

            let db = Firestore.firestore()
            let userRef = db.collection("users").document(user.email ?? user.uid)

            userRef.setData([
                "name": fullName.isEmpty ? "User" : fullName,
                "email": user.email ?? "",
                "profileImageURL": ""
            ]) { error in
                if let error = error {
                    print("❌ Firestore Error: \(error.localizedDescription)")
                    self.errorMessage = "Kunne ikke lagre brukerinformasjon."
                } else {
                    print("✅ User document created successfully!")
                    self.errorMessage = nil  // ✅ Clear error message on success
                }
            }

            loginUser()
        }
    }

    func resetPassword() {
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            if let error = error {
                self.errorMessage = error.localizedDescription
            } else {
                self.errorMessage = "Passordtilbakestilling sendt!"
            }
        }
    }

    func generateQRCode(from string: String) -> UIImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.setValue(Data(string.utf8), forKey: "inputMessage")

        if let outputImage = filter.outputImage {
            let transform = CGAffineTransform(scaleX: 10, y: 10)
            let scaledImage = outputImage.transformed(by: transform)
            if let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) {
                return UIImage(cgImage: cgImage)
            }
        }
        return nil
    }
}

#Preview {
    LoginRegisterView(
        isSignedIn: .constant(false),
        userName: .constant(""),
        userEmail: .constant(""),
        qrCode: .constant(nil),
        userImage: .constant(UIImage(systemName: "person.circle.fill"))  // ✅ Pass user image correctly
    )
}
