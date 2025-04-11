import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

class UserManager: ObservableObject {
    @Published var name: String = ""
    @Published var email: String = ""
    @Published var phoneNumber: String = ""  // ✅ Added phoneNumber
    @Published var birthday: String = ""
    @Published var address: String = ""
    @Published var postcode: String = ""
    @Published var postPlace: String = ""
    @Published var flowUID: String = ""
    @Published var profileImage: UIImage? = nil

    // ✅ Function to update user data from Firestore document
    func updateUserData(from document: [String: Any]) {
        DispatchQueue.main.async {
            self.name = document["name"] as? String ?? ""
            self.email = document["email"] as? String ?? ""
            self.phoneNumber = document["phoneNumber"] as? String ?? ""  // ✅ Added phoneNumber
            self.birthday = document["birthday"] as? String ?? ""
            self.address = document["address"] as? String ?? ""
            self.postcode = document["postcode"] as? String ?? ""
            self.postPlace = document["postPlace"] as? String ?? ""
            self.flowUID = document["flowUID"] as? String ?? ""

            // ✅ Load profile image from Firestore URL
            if let imageURLString = document["profileImageURL"] as? String,
               let url = URL(string: imageURLString) {
                DispatchQueue.global().async {
                    if let imageData = try? Data(contentsOf: url),
                       let uiImage = UIImage(data: imageData) {
                        DispatchQueue.main.async {
                            self.profileImage = uiImage
                        }
                    }
                }
            }
        }
    }
}
