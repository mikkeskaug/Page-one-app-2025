//
//  LocationManager.swift
//  Page one kundeklubb
//
//  Created by Service on 05/02/2025.
//

import MapKit
import CoreLocation

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    @Published var userLocation: CLLocationCoordinate2D?

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }

    func requestLocation() {
        let status = locationManager.authorizationStatus
        
        switch status {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            print("✅ Location permission granted! Fetching user location...")
            locationManager.requestLocation()  // 🔹 Fetch location **once** instead of continuous updates
        case .denied, .restricted:
            print("❌ Location access denied. Please enable it in Settings.")
        default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            DispatchQueue.main.async {
                self.userLocation = location.coordinate
                print("✅ User Location Updated: \(location.coordinate.latitude), \(location.coordinate.longitude)")
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("❌ Failed to get user location: \(error.localizedDescription)")
    }
}
