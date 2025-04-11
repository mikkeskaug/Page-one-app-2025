//
//  KundeKlubbView.swift
//  Page one kundeklubb
//
//  Created by Service on 05/02/2025.
//

//
//  ContentView.swift
//  Page one kundeklubb
//
//  Created by Service on 30/01/2025.
//

import SwiftUI
import AuthenticationServices
import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import CoreImage.CIFilterBuiltins
import UIKit
import FirebaseMessaging
import UserNotifications
import FirebaseInAppMessaging

struct KundeKlubbView: View {
    @State private var isSignedIn = false
    @State private var userName: String = ""
    @State private var userEmail: String = ""
    @State private var userImage: UIImage? = UIImage(systemName: "person.circle.fill")
    @State private var qrCode: UIImage? = nil
    @State private var offers: [String] = ["10% off next purchase", "Buy 1 Get 1 Free", "Exclusive VIP Deal"]
    @State private var isRegistering = false
    @State private var email = ""
    @State private var password = ""
    @State private var fullName = ""
    @State private var errorMessage: String?
    @State private var showLoginRegister = false
    @State private var showImagePicker = false
    @State private var showSettings = false  // ✅ Fixed: Now properly declared
    @State private var selectedImage: UIImage?
    @StateObject private var viewModel = ItemViewModel()
    @State private var userBirthday: String = ""
    @State private var userAddress: String = ""
    @State private var userFlowUID: String = ""
    @State private var showLogoutConfirmation = false  // ✅ New State for Alert
    @EnvironmentObject var userManager: UserManager  // ✅ Access user data


    var body: some View {
            VStack {
                if isSignedIn {
                    // ✅ Settings icon in top-right corner, only when signed in
                    HStack {
                        Spacer()
                        Button(action: {
                            showSettings = true
                        }) {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 24))  // ✅ Smaller icon
                                .foregroundColor(.gray)
                                .padding()
                        }
                    }

                    VStack {
                        Button(action: {
                            showImagePicker = true
                        }) {
                            if let userImage = userImage {
                                Image(uiImage: userImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 120, height: 120)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color.gray, lineWidth: 2))
                                    .shadow(radius: 5)
                                    .padding(.top, 20)
                            }
                        }
                        .sheet(isPresented: $showImagePicker) {
                            ImagePicker(image: $selectedImage, onImagePicked: uploadProfileImage)
                        }

                        Text("Velkommen, \(userName)!")
                            .font(.title)
                            .fontWeight(.bold)
                            .padding(.top, 5)

                        Text(userEmail)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .padding(.bottom, 10)

                        if let qr = qrCode {
                            Image(uiImage: qr)
                                .resizable()
                                .interpolation(.none)
                                .scaledToFit()
                                .frame(width: 150, height: 150)
                                .padding(.vertical, 10)
                        }
                    }

                   

                    List(viewModel.items) { item in
                        Text(item.name)
                    }
                    .listStyle(InsetGroupedListStyle())
                    .frame(maxHeight: 250)
                    .padding(.top, 10)
                    .onAppear {
                        viewModel.fetchItems()
                    }
                    Button("Logg Ut") {
                        showLogoutConfirmation = true  // ✅ Show alert on tap
                     
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding(.horizontal, 40)
                    .padding(.top, 20)
                    .alert(isPresented: $showLogoutConfirmation) {  // ✅ Logout Confirmation Alert
                                        Alert(
                                            title: Text("Logg ut"),
                                            message: Text("Er du sikker på at du vil logge ut?"),
                                            primaryButton: .destructive(Text("Logg ut")) {
                                                signOut()  // ✅ Only log out if confirmed
                                            },
                                            secondaryButton: .cancel(Text("Avbryt"))
                                        )
                                    }
                    
                } else {
                    VStack {
                        Text("Velkommen til\nPage one kundeklubb")
                            .padding()
                            .font(.title)
                            .multilineTextAlignment(.center)
                            .fontWeight(.bold)

                        SignInWithAppleButton(.continue) { request in
                            request.requestedScopes = [.fullName, .email]
                        } onCompletion: { result in
                            handleSignIn(result: result)
                        }
                        .frame(height: 50)
                        .padding()

                        Button("Logg inn / Registrer") {
                            showLoginRegister = true
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.horizontal, 40)
                    }
                    .sheet(isPresented: $showLoginRegister) {
                        LoginRegisterView(
                            isSignedIn: $isSignedIn,
                            userName: $userName,
                            userEmail: $userEmail,
                            qrCode: $qrCode,
                            userImage: $userImage
                        )
                    }
                }
            }
            .onAppear {
                checkSignInStatus()
                requestNotificationPermission()
                viewModel.fetchItems()
            }
            .sheet(isPresented: $showSettings) {
                SettingsView(
                    
                )
            }
        }
    


    func checkSignInStatus() {
          if let user = Auth.auth().currentUser {
              let db = Firestore.firestore()
              let userRef = db.collection("users").document(user.email ?? "")
              userRef.getDocument { document, error in
                  if let document = document, document.exists {
                      self.userName = document["name"] as? String ?? "User"
                      self.userEmail = user.email ?? "No Email"
                      self.isSignedIn = true
                      self.qrCode = generateQRCode(from: self.userEmail)
                  }
              }
          }
        else {
            fetchUserData()
        }
      }

    func handleSignIn(result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let auth):
            if let appleIDCredential = auth.credential as? ASAuthorizationAppleIDCredential,
               let identityTokenData = appleIDCredential.identityToken,
               let idTokenString = String(data: identityTokenData, encoding: .utf8) {
                
                let credential = OAuthProvider.credential(
                    providerID: AuthProviderID.apple,
                    idToken: idTokenString,
                    rawNonce: ""
                )
                
                Auth.auth().signIn(with: credential) { authResult, error in
                    if let error = error {
                        print("Error signing in: \(error.localizedDescription)")
                        return
                    }
                    
                    guard let user = authResult?.user else { return }
                    
                    let db = Firestore.firestore()
                    let userRef = db.collection("users").document(user.email ?? user.uid)
                    
                    // Get the full name if it's available
                    let fullName = "\(appleIDCredential.fullName?.givenName ?? "") \(appleIDCredential.fullName?.familyName ?? "")".trimmingCharacters(in: .whitespaces)
                    
                    userRef.getDocument { (document, error) in
                        if let document = document, document.exists {
                            print("User already exists, skipping name update")
                        } else {
                            // Save name only for first-time users
                            userRef.setData([
                                "name": fullName.isEmpty ? "User" : fullName,
                                "email": user.email ?? "",
                                "profileImageURL": ""
                            ]) { error in
                                if let error = error {
                                    print("Error saving user data: \(error.localizedDescription)")
                                }
                            }
                        }
                    }
                    
                    self.isSignedIn = true
                    self.userEmail = user.email ?? ""
                    self.userName = fullName.isEmpty ? "User" : fullName
                    self.qrCode = generateQRCode(from: self.userEmail)
                    
                    DispatchQueue.main.async {
                               self.fetchUserData()  // Fetch user details after Apple Sign-In
                           }
                }
                
            }
        case .failure(let error):
            print("Sign in with Apple failed: \(error.localizedDescription)")
        }
    }
    
    
    
    func fetchUserData() {
        print("FETCHUSERDATAISCALLED")
            if let user = Auth.auth().currentUser {
                let db = Firestore.firestore()
                let docRef = db.collection("users").document(user.email ?? "")
                
                docRef.getDocument { (document, error) in
                    if let document = document, document.exists {
                        self.userName = document.data()? ["name"] as? String ?? "User"
                        self.userEmail = user.email ?? ""
                        if let imageURLString = document.data()? ["profileImageURL"] as? String, let url = URL(string: imageURLString) {
                            DispatchQueue.global().async {
                                if let imageData = try? Data(contentsOf: url), let uiImage = UIImage(data: imageData) {
                                    DispatchQueue.main.async {
                                        self.userImage = uiImage
                                    }
                                }
                            }
                        }
                        self.qrCode = generateQRCode(from: self.userEmail)
                        self.isSignedIn = true
                    }
                }
            }
        }
    
    
    func loginUser() {
        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            if let error = error {
                print("❌ Error signing in: \(error.localizedDescription)")
                return
            }

            print("✅ Login successful")
           
            DispatchQueue.main.async {
                print("WE CAME THIS FAR")
                self.fetchUserData()  // Fetch user details after login
            }
        }
    }
    
    func registerUser() {
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let error = error {
                print("Error registering: \(error.localizedDescription)")
                return
            }
            
            guard let user = authResult?.user else { return }
            
            let db = Firestore.firestore()
            let userRef = db.collection("users").document(user.email ?? user.uid)
            
            // Create user document in Firestore
            userRef.setData([
                "name": fullName.isEmpty ? "User" : fullName,
                "email": user.email ?? "",
                "profileImageURL": ""
            ]) { error in
                if let error = error {
                    print("Error saving user data: \(error.localizedDescription)")
                } else {
                    print("User document created successfully!")
                }
            }
            
            loginUser()  // Call login to update state
        }
    }
    
    func signOut() {
            do {
                try Auth.auth().signOut()
                isSignedIn = false
                userName = ""
                userEmail = ""
                qrCode = nil
                userImage = UIImage(systemName: "person.circle.fill")
                
                DispatchQueue.main.async {
                            userManager.name = ""
                            userManager.email = ""
                            userManager.phoneNumber = ""
                            userManager.birthday = ""
                            userManager.address = ""
                            userManager.postcode = ""
                            userManager.postPlace = ""
                            userManager.flowUID = ""
                            userManager.profileImage = nil
                        }
                
            } catch {
                print("Error signing out: \(error.localizedDescription)")
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
    
    func resetPassword() {
            Auth.auth().sendPasswordReset(withEmail: email) { error in
                if let error = error {
                    print("Error sending reset email: \(error.localizedDescription)")
                } else {
                    print("Password reset email sent.")
                }
            }
        }
    
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
    }
    
    func uploadProfileImage(_ image: UIImage) {
            guard let user = Auth.auth().currentUser, let imageData = image.jpegData(compressionQuality: 0.5) else { return }
           
        let storageRef = Storage.storage().reference().child("profile_images/\(user.uid)/profile.jpg")
      
        
            storageRef.putData(imageData, metadata: nil) { metadata, error in
                if let error = error {
                    print("Error uploading image: \(error.localizedDescription)")
                    return
                }
                storageRef.downloadURL { url, error in
                    if let url = url {
                        Firestore.firestore().collection("users").document(user.email ?? "").updateData(["profileImageURL": url.absoluteString])
                        fetchUserData()
                    }
                }
            }
        }
    
    struct ImagePicker: UIViewControllerRepresentable {
        @Binding var image: UIImage?
        var onImagePicked: (UIImage) -> Void
        
        class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
            var parent: ImagePicker
            
            init(parent: ImagePicker) {
                self.parent = parent
            }
            
            func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
                if let image = info[.originalImage] as? UIImage {
                    parent.image = image
                    parent.onImagePicked(image)
                }
                picker.dismiss(animated: true)
            }
        }
        
        func makeCoordinator() -> Coordinator {
            Coordinator(parent: self)
        }
        
        func makeUIViewController(context: Context) -> UIImagePickerController {
            let picker = UIImagePickerController()
            picker.delegate = context.coordinator
            return picker
        }
        
        func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    }

}
#Preview {
    ContentView()
}
