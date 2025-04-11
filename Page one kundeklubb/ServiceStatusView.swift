//
//  ServiceStatusView.swift
//  Page one kundeklubb
//
//  Created by Service on 05/02/2025.
//

import SwiftUI
import Combine
import Foundation

struct ServiceStatusView: View {
    @State private var orderNumber: String = ""
    @State private var phoneNumber: String = ""
    @State private var serviceStage: Int = 0
    @State private var statusMessage: String = "Skriv inn serviceinformasjon"
    @State private var isLoading: Bool = false
    @State private var delerText: String = ""
    @State private var fakturaText: String = ""
    @State private var animatedProgress: Double = 0.0
    @State private var cancellable: AnyCancellable?

    var progressPercentage: Int {
        return Int((animatedProgress / 4) * 100)
    }

    // 🎨 Function to Get Progress Bar Color Based on Stage
    func getProgressColor() -> Color {
        switch serviceStage {
        case 1: return .red       // 📦 Order Received
        case 2: return .orange    // ⏳ Waiting for Parts
        case 3: return .yellow    // 🛠 Under Repair
        case 4: return .green     // ✅ Completed
        default: return .gray     // ❓ Unknown
        }
    }

    var body: some View {
        VStack {
            Text("Sjekk servicestatus")
                .font(.title)
                .fontWeight(.bold)
                .padding(.top, 20)

            TextField("Serviceordrenummer", text: $orderNumber)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            TextField("Telefonnummer", text: $phoneNumber)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            Button(action: fetchServiceStatus) {
                Text("Søk")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding(.horizontal, 40)
            }
            .padding(.top, 10)

            if isLoading {
                ProgressView()
                    .padding()
            }

            // 📊 Enhanced Progress Bar with Color Changes
            VStack {
                ProgressView(value: animatedProgress, total: 4)
                    .progressViewStyle(LinearProgressViewStyle())
                    .scaleEffect(x: 1, y: 3, anchor: .center) // ✅ Thicker bar
                    .animation(.spring(response: 0.6, dampingFraction: 0.7), value: animatedProgress)
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 10)
                    .accentColor(getProgressColor()) // ✅ Dynamic color change

                Text("\(progressPercentage)% fullført")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(getProgressColor()) // ✅ Change percentage color too
                    .padding(.bottom, 20)
            }

            // 🎯 Status Message with Icon
            HStack {
                Text(getStatusIcon() + " " + statusMessage)
                    .font(.headline)
                    .padding()
                    .multilineTextAlignment(.center)
                    .transition(.opacity)
            }
            .animation(.easeInOut(duration: 0.5), value: statusMessage)

            // ✅ Show "Deler" field if service is completed
            if serviceStage == 4 {
                VStack {
                    Text("🛠 Reparasjon:")
                        .font(.headline)
                        .bold()
                        .padding(.top, 10)
                    Text(delerText)
                        .font(.body)
                        .italic()
                        .padding()
                        .multilineTextAlignment(.center)
                        .transition(.opacity)
                }
                .animation(.easeIn(duration: 0.5), value: delerText)
            }

            // ✅ Show Invoice Amount (Faktura_belop) if it's not empty
            if !fakturaText.isEmpty {
                VStack {
                    Text("💳 Fakturabeløp:")
                        .font(.headline)
                        .bold()
                        .padding(.top, 10)
                    Text("\(fakturaText) kr")
                        .font(.body)
                        .italic()
                        .padding()
                        .multilineTextAlignment(.center)
                        .transition(.opacity)
                }
                .animation(.easeIn(duration: 0.5), value: fakturaText)
            }

            Spacer()
        }
        .padding()
    }

    // 🏆 Get Icon Based on Status
    func getStatusIcon() -> String {
        switch serviceStage {
        case 1: return "📦"  // Order Received
        case 2: return "⏳"  // Waiting for Parts
        case 3: return "🛠"  // Under Repair
        case 4: return "✅"  // Service Completed
        default: return "❓"
        }
    }

    func fetchServiceStatus() {
        guard !orderNumber.isEmpty, !phoneNumber.isEmpty else {
            statusMessage = "Vennligst fyll ut alle feltene"
            return
        }

        isLoading = true
        statusMessage = "Henter servicestatus..."

        let urlString = "http://213.239.106.126/fmi/xml/fmresultset.xml?-db=AppleBase&-lay=XML&Loggnummer=\(orderNumber)&XMLTelefon=\(phoneNumber)&-find"

        guard let url = URL(string: urlString) else {
            statusMessage = "Ugyldig URL"
            isLoading = false
            return
        }

        cancellable = URLSession.shared.dataTaskPublisher(for: url)
            .map { $0.data }
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                isLoading = false
                if case .failure(let error) = completion {
                    statusMessage = "Feil ved henting: \(error.localizedDescription)"
                }
            }, receiveValue: { data in
                parseXML(data: data)
            })
    }

    func parseXML(data: Data) {
        let parser = XMLParser(data: data)
        let xmlParserDelegate = ServiceXMLParser()
        parser.delegate = xmlParserDelegate

        if parser.parse() {
            if xmlParserDelegate.xmlStages.isEmpty {
                statusMessage = "Kunne ikke finne status i responsen"
                serviceStage = 0
            } else {
                updateServiceStage(from: xmlParserDelegate.xmlStages)
            }
        } else {
            statusMessage = "Feil ved parsing av XML"
            serviceStage = 0
        }
    }

    func updateServiceStage(from xmlStages: [String: String]) {
        if xmlStages["XMLferdig"] == "Ja" {
            serviceStage = 4
            statusMessage = "✅ Service er fullført!"
            delerText = xmlStages["Deler"] ?? "Ingen informasjon tilgjengelig"
            fakturaText = xmlStages["Faktura_belop"] ?? ""
        } else if xmlStages["XMLunderRep"] == "Ja" {
            serviceStage = 3
            statusMessage = "🛠 Service er under reparasjon"
            delerText = ""
            fakturaText = ""
        } else if xmlStages["XMLventerDeler"] == "Ja" {
            serviceStage = 2
            statusMessage = "⏳ Venter på reservedeler"
            delerText = ""
            fakturaText = ""
        } else if xmlStages["XMLmottatt"] == "Ja" {
            serviceStage = 1
            statusMessage = "📦 Serviceordre mottatt"
            delerText = ""
            fakturaText = ""
        } else {
            serviceStage = 0
            statusMessage = "❓ Ingen status tilgjengelig"
            delerText = ""
            fakturaText = ""
        }

        // ✅ Animate progress bar update
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            animatedProgress = Double(serviceStage)
        }
    }
}
#Preview {
    ServiceStatusView()
}
