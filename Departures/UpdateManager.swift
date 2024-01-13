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
    private var updateInProgress = false
    let queue = OperationQueue()
    
    @Published var location: CLLocation? = nil
    @Published var locationString: String = "Loc unknown"
    @Published var stnsDeps: [StationDepartures] = [StationDepartures]()
    @Published var depsLastUpdated: Date? = nil
    
    override init() {
        super.init()
        queue.maxConcurrentOperationCount = 1
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 200
        locationManager.startUpdatingLocation()
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
    
    @MainActor func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if locations.count > 0 {
            location = locations.first
        } else {
            location = nil
        }
        guard let newLoc = location else {
            locationString = "Loc unavailable"
            return
        }
        location = newLoc
        locationString = String(format: "[%.2f, %.2f]", location!.coordinate.latitude, location!.coordinate.longitude)
        updateDepartures()

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
            print("Finished updating departures for location \(loc.coordinate.latitude), \(loc.coordinate.longitude), count: \(stnsDeps.count)")
        } catch {
            print("Error fetching departures, URL: \(url)")
        }
    }
    
    @MainActor
    func updateDepartures(force: Bool = false) {
        queue.waitUntilAllOperationsAreFinished()
        queue.addOperation {
            if !self.updateInProgress {
                self.updateInProgress = true
                if (self.lastUpdateStarted != nil && self.lastUpdateStarted!.timeIntervalSinceNow > -120) {
                    print("Data is <2min old and force update is not specified, skipping...")
                    return
                }
                self.lastUpdateStarted = Date()
                print("Starting departure update, lastUpdateStarted=\(self.lastUpdateStarted != nil ? self.lastUpdateStarted!.timeIntervalSinceNow : 0)")
        //        print("Starting departure update, force=\(force), lastUpdateStarted=\(lastUpdateStarted != nil ? lastUpdateStarted!.timeIntervalSinceNow : nil)")
                
                guard let loc = self.location else {
                    print("Location not available")
                    return
                }
                print("Updating departures with location \(self.locationString)...")
                Task {
                    await self.updateHelper(loc: loc)
                }
            }
            self.updateInProgress = false
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
