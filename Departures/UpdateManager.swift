//
//  Location.swift
//  Departures
//
//  Created by Vinay Hiremath on 2024-01-11.
//

import SwiftUI
import CoreLocation

class UpdateManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    private var lastUpdateStarted: Date? = nil
    
    @Published var location: CLLocation? = nil
    @Published var locationString: String = "Loc unknown"
    @Published var stnsDeps: [StationDepartures] = [StationDepartures]()
    @Published var depsLastUpdated: Date? = nil
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 200
        locationManager.startUpdatingLocation()
        startUpdatingDepartures()
    }
    
    
    private static func reqUrl(loc: CLLocation) -> String {
//        TODO: Use stop types preferences
//        var stopTypes: [String] = []
//        if configuration.metroStations {
//            stopTypes.append("NaptanMetroStation")
//        }
//        if configuration.railStations {
//            stopTypes.append("NaptanRailStation")
//        }
//        if configuration.busStations {
//            stopTypes.append("NaptanPublicBusCoachTram")
//        }
//        let stopTypesString = stopTypes.joined(separator: ",")
        let stopTypesString = "NaptanMetroStation,NaptanRailStation"
        return "https://departures-backend.azurewebsites.net/api/nearest?lat=\(loc.coordinate.latitude)&lng=\(loc.coordinate.longitude)&stopTypes=\(stopTypesString)"
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        location = locations.last
        guard let location = location else {
            locationString = "Loc unavailable"
            return
        }
        locationString = String(format: "[%.2f, %.2f]", location.coordinate.latitude, location.coordinate.longitude)
        Task {
            print("Location requested updating departures")
            await updateDepartures()
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        location = nil
        locationString = "Loc error: \(error.localizedDescription)"
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:  // Location services are available.
            locationManager.startUpdatingLocation()
            break
        case .restricted, .denied:  // Location services currently unavailable.
            locationString = "Loc access denied"
            break
        case .notDetermined:        // Authorization not determined yet.
            manager.requestAlwaysAuthorization()
            break
        default:
            break
        }
    }
    
    func updateHelper(loc: CLLocation) async {
        let url = URL(string: UpdateManager.reqUrl(loc: loc))!
        do {
            let (data, _) = try await URLSession.shared.data(from: url) // Fetch JSON
            
            try await MainActor.run {
                stnsDeps = try JSONDecoder().decode([StationDepartures].self, from: data) // Parse JSON
                depsLastUpdated = Date()
            }
            print("\tFinished updating departures for location \(loc.coordinate.latitude), \(loc.coordinate.longitude), count: \(stnsDeps.count)")
        } catch {
            print("\tError fetching departures, URL: \(url)")
        }
    }
    
    func updateDepartures(force: Bool = false) async {
        if !force && lastUpdateStarted != nil && lastUpdateStarted!.timeIntervalSinceNow > -120.0 {
            print("\tData is <2min old and force update is not specified, skipping...")
            return
        }
        guard let loc = location else {
            print("\tLocation not available")
            return
        }
        lastUpdateStarted = Date()
        print("\tUpdating departures with location \(locationString)...")
        await updateHelper(loc: loc)
    }
    
    func startUpdatingDepartures(secInterval: Double = 180.0) {
        Task {
            print("Dispatch queue requested updating departures")
            await updateDepartures()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + secInterval) { [weak self] in
            self?.startUpdatingDepartures()
        }
    }
    
    static func example() -> UpdateManager {
        let updateManager = UpdateManager()
        if let url = Bundle.main.url(forResource: "sampleDepartures", withExtension: "json") {
            do {
                let jsonData = try Data(contentsOf: url)
                updateManager.stnsDeps = try JSONDecoder().decode([StationDepartures].self, from: jsonData)
            } catch {
                updateManager.stnsDeps = []
            }
        } else {
            updateManager.stnsDeps = []
        }
        return updateManager
    }
    
    // TODO: Maybe add fn to get location from postcode or allowing user to set lat/lon
}
