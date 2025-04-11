import SwiftUI
import Foundation
import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

struct SettingsView: View {
    @EnvironmentObject var userManager: UserManager

    @State private var newPhoneNumber = "" // ✅ Added phone number field
    @State private var newBirthday = ""
    @State private var newAddress = ""
    @State private var newFlowUID = ""
    @State private var newPostcode = ""
    @State private var newPostPlace = ""
    @State private var successMessage: String?
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage?

    var body: some View {
        VStack {
            Text("⚙️ Valg")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 20)

            // ✅ Profile Image with Tap to Change
            Button(action: {
                showImagePicker = true
            }) {
                if let profileImage = userManager.profileImage {
                    Image(uiImage: profileImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.gray, lineWidth: 2))
                        .shadow(radius: 5)
                        .padding(.top, 10)
                } else {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                        .foregroundColor(.gray)
                        .padding(.top, 10)
                }
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $selectedImage, onImagePicked: uploadProfileImage)
            }

            // ✅ Display Name & Email
            VStack {
                Text(userManager.name)
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top, 10)

                Text(userManager.email)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            .padding(.bottom, 20)

            // ✅ Form Fields
            TextField("Telefonnummer", text: $newPhoneNumber)  // ✅ Added phone number input
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.phonePad)
                .padding()

            TextField("Fødselsdag", text: $newBirthday)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            TextField("Adresse", text: $newAddress)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            TextField("Postnummer", text: $newPostcode)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            TextField("Poststed", text: $newPostPlace)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            TextField("FlowUID (valgfritt)", text: $newFlowUID)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            if let success = successMessage {
                Text(success)
                    .foregroundColor(.green)
                    .font(.callout)
                    .padding()
            }

            Button("Lagre endringer") {
                saveUserSettings()
            }
            .frame(height: 50)
            .frame(maxWidth: .infinity)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
            .padding(.horizontal, 40)

            Spacer()
        }
        .onAppear {
            print("🔍 SettingsView appeared, loading user settings...")
            loadUserSettings()
        }
    }

    func loadUserSettings() {
        guard let user = Auth.auth().currentUser else {
            print("❌ No authenticated user found")
            return
        }

        let db = Firestore.firestore()
        let docRef = db.collection("users").document(user.email ?? "")

        docRef.getDocument { (document, error) in
            if let error = error {
                print("❌ Error fetching user data: \(error.localizedDescription)")
                return
            }

            guard let document = document, document.exists else {
                print("❌ User document not found in Firestore")
                return
            }

            let data = document.data() ?? [:]
            print("✅ User data fetched: \(data)")

            DispatchQueue.main.async {
                // ✅ Assign values to userManager
                userManager.updateUserData(from: data)

                // ✅ Ensure UI is updated with Firestore values
                newPhoneNumber = data["phoneNumber"] as? String ?? ""
                newBirthday = data["birthday"] as? String ?? ""
                newAddress = data["address"] as? String ?? ""
                newPostcode = data["postcode"] as? String ?? ""
                newPostPlace = data["postPlace"] as? String ?? ""
                newFlowUID = data["flowUID"] as? String ?? ""
            }
        }
    }

    // ✅ Save updated settings to Firestore
    func saveUserSettings() {
        guard let user = Auth.auth().currentUser else { return }
        let db = Firestore.firestore()
        let docRef = db.collection("users").document(user.email ?? "")

        let updatedData: [String: Any] = [
            "phoneNumber": newPhoneNumber, // ✅ Save phone number
            "birthday": newBirthday,
            "address": newAddress,
            "postcode": newPostcode,
            "postPlace": newPostPlace,
            "flowUID": newFlowUID
        ]

        docRef.updateData(updatedData) { error in
            if error == nil {
                DispatchQueue.main.async {
                    userManager.phoneNumber = newPhoneNumber // ✅ Update UserManager
                    userManager.birthday = newBirthday
                    userManager.address = newAddress
                    userManager.postcode = newPostcode
                    userManager.postPlace = newPostPlace
                    userManager.flowUID = newFlowUID
                    successMessage = "Dine innstillinger er lagret!"
                }
            }
        }
    }
    
    func updateUserData(from document: [String: Any]) {
        DispatchQueue.main.async {
           
            self.newPhoneNumber = document["phonenumber"] as? String ?? self.newPhoneNumber
            self.newBirthday = document["birthday"] as? String ?? self.newBirthday
            self.newAddress = document["address"] as? String ?? self.newAddress
            self.newPostcode = document["postcode"] as? String ?? self.newPostcode
            self.newPostPlace = document["postPlace"] as? String ?? self.newPostPlace
            self.newFlowUID = document["flowUID"] as? String ?? self.newFlowUID
        }
    }

    // ✅ Upload profile image to Firebase Storage
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
                    DispatchQueue.main.async {
                        userManager.profileImage = image
                        loadUserSettings()
                    }
                }
            }
        }
    }
}

