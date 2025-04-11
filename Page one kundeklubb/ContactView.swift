//
//  ContactView.swift
//  Page one kundeklubb
//
//  Created by Service on 06/02/2025.
//

import SwiftUI

struct ContactView: View {
    let phoneNumber = "33361100"
    let email = "butikk@pageone.no"

    var body: some View {
        VStack(spacing: 30) { // ✅ Improved spacing
            Text("📞 Kontakt oss")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 50) // ✅ More space above

            Spacer().frame(height: 20) // ✅ More space between header and buttons

            // 📞 Call Button
            Button(action: callStore) {
                HStack {
                    Image(systemName: "phone.fill")
                        .font(.title2)
                    Text("Ring oss: 333 61 100")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .padding(.horizontal, 40)

            // 📧 Email Button
            Button(action: sendEmail) {
                HStack {
                    Image(systemName: "envelope.fill")
                        .font(.title2)
                    Text("Send oss en e-post")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .padding(.horizontal, 40)

            // 💬 iMessage Button
            Button(action: sendMessage) {
                HStack {
                    Image(systemName: "message.fill")
                        .font(.title2)
                    Text("Send oss en iMessage")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.purple)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .padding(.horizontal, 40)
            Text("iMessage ")
            Spacer()
        }
        .padding()
    }

    // 📞 Call Function
    func callStore() {
        if let phoneURL = URL(string: "tel://\(phoneNumber)"),
           UIApplication.shared.canOpenURL(phoneURL) {
            UIApplication.shared.open(phoneURL)
        }
    }

    // 📧 Email Function
    func sendEmail() {
        if let emailURL = URL(string: "mailto:\(email)"),
           UIApplication.shared.canOpenURL(emailURL) {
            UIApplication.shared.open(emailURL)
        }
    }

    // 💬 iMessage Function
    func sendMessage() {
        if let messageURL = URL(string: "sms:\(email)"),
           UIApplication.shared.canOpenURL(messageURL) {
            UIApplication.shared.open(messageURL)
        }
    }
}

#Preview {
    ContactView()
}
