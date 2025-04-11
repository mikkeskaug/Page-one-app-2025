//
//  MapView.swift
//  Page one kundeklubb
//
//  Created by Service on 05/02/2025.
//

import SwiftUI
import MapKit
import CoreLocation

struct MapView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var cameraPosition: MapCameraPosition = .automatic // Auto-adjusts the view
    
    let destinationCoordinate = CLLocationCoordinate2D(latitude: 59.268864, longitude: 10.410251)

    var body: some View {
        ZStack(alignment: .bottom) {
            // 📌 Full-screen Map with both locations
            Map(position: $cameraPosition) {
                if let userLocation = locationManager.userLocation {
                    Marker("Your Location", coordinate: userLocation)
                }
                Marker("Destination", coordinate: destinationCoordinate)
            }
            .edgesIgnoringSafeArea(.all)
            .onReceive(locationManager.$userLocation) { newLocation in
                if let newLocation = newLocation {
                    print("📍 User location received! Updating map...")
                    updateCameraPosition()
                }
            }

            // 🚗 Button to Open Apple Maps for Navigation
            Button(action: openAppleMaps) {
                Text("Get Directions")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding(.horizontal, 20)
            }
            .padding(.bottom, 60) // 🔹 Increased bottom padding to avoid overlap
        }
        .onAppear {
            locationManager.requestLocation()
        }
    }

    // 🗺 Open Apple Maps for Navigation
    func openAppleMaps() {
        guard let userLocation = locationManager.userLocation else { return }
        let userLat = userLocation.latitude
        let userLng = userLocation.longitude
        let destinationLat = destinationCoordinate.latitude
        let destinationLng = destinationCoordinate.longitude

        let url = URL(string: "http://maps.apple.com/?saddr=\(userLat),\(userLng)&daddr=\(destinationLat),\(destinationLng)&dirflg=d")!
        UIApplication.shared.open(url)
    }

    // 📍 Adjust Map to Fit Both Locations (With More Zoom-Out)
    func updateCameraPosition() {
        guard let userLocation = locationManager.userLocation else {
            print("⚠️ No user location yet!")
            return
        }

        let coordinates = [userLocation, destinationCoordinate]
        let latitudes = coordinates.map { $0.latitude }
        let longitudes = coordinates.map { $0.longitude }

        let minLat = latitudes.min()!
        let maxLat = latitudes.max()!
        let minLng = longitudes.min()!
        let maxLng = longitudes.max()!

        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLng + maxLng) / 2
        )

        let span = MKCoordinateSpan(
            latitudeDelta: (maxLat - minLat) * 2.0,  // 🔹 Increased zoom-out factor from 1.5 to 2.0
            longitudeDelta: (maxLng - minLng) * 2.0
        )

        DispatchQueue.main.async {
            cameraPosition = .region(MKCoordinateRegion(center: center, span: span))
            print("✅ Map region updated to fit user and destination")
        }
    }
}

#Preview {
    MapView()
}
