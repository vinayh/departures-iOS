//
//  Location.swift
//  Departures
//
//  Created by Vinay Hiremath on 2024-01-11.
//

import os
import SwiftUI
import CoreLocation

class UpdateManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    private var lastDepUpdateStarted: Date? = nil
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "UpdateManager")
    
    @Published var location: CLLocation? = nil
    @Published var locationString: String = "Unknown"
    @Published var stnsDeps: [StationDepartures] = [StationDepartures]()
    @Published var lastDepUpdateFinished: Date? = nil
    @Published var numCurrentlyUpdating: Int = 0
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 200
        locationManager.startUpdatingLocation()
        startUpdatingDepartures()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        location = locations.last
        guard let location = location else {
            locationString = "Unavailable"
            return
        }
        reverseGeocode(loc: location)
        Task {
            logger.log("locationManager - updating departures")
            await updateDepartures()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        location = nil
        locationString = "Error"
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:  // Location services are available.
            locationManager.startUpdatingLocation()
            break
        case .restricted, .denied:  // Location services currently unavailable.
            locationString = "Access denied"
            break
        case .notDetermined:        // Authorization not determined yet.
            manager.requestAlwaysAuthorization()
            break
        default:
            break
        }
    }
    
    private func reverseGeocode(loc: CLLocation) {
        locationString = String(format: "[%.2f, %.2f]", loc.coordinate.latitude, loc.coordinate.longitude)
        geocoder.reverseGeocodeLocation(loc, completionHandler: {(placemarks, error) -> Void in
            if let postalCode = placemarks?.first?.postalCode {
                self.locationString = postalCode
            }
        })
    }
    
    private static func reqUrl(loc: CLLocation, configuration: ConfigurationAppIntent? = nil) -> URL {
        //        TODO: Use stop types preferences
        var stopTypesString: String = "NaptanMetroStation,NaptanRailStation"
        
        if let cfg = configuration {
            var stopTypes: [String] = []
            if cfg.metroStations {
                stopTypes.append("NaptanMetroStation")
            }
            if cfg.railStations {
                stopTypes.append("NaptanRailStation")
            }
            if cfg.busStations {
                stopTypes.append("NaptanPublicBusCoachTram")
            }
            stopTypesString = stopTypes.joined(separator: ",")
        }
        
        let urlString = "https://departures-backend.azurewebsites.net/api/nearest?lat=\(loc.coordinate.latitude)&lng=\(loc.coordinate.longitude)&stopTypes=\(stopTypesString)"
        return URL(string: urlString)!
    }
    
    @MainActor
    private func updateDeparturesHelper(loc: CLLocation, configuration: ConfigurationAppIntent? = nil) async {
        self.numCurrentlyUpdating += 1
        let url = UpdateManager.reqUrl(loc: loc)
        do {
            let (data, _) = try await URLSession.shared.data(from: url) // Fetch JSON
            stnsDeps = try JSONDecoder().decode([StationDepartures].self, from: data) // Parse JSON
            lastDepUpdateFinished = Date()
            logger.log("Finished updating departures for location \(self.locationString), station count: \(self.stnsDeps.count)")
        } catch {
            logger.error("Error fetching departures, req URL: \(url.absoluteString)")
        }
        self.numCurrentlyUpdating -= 1
    }
    
    func updateDepartures(force: Bool = false, configuration: ConfigurationAppIntent? = nil) async {
        if !force && lastDepUpdateStarted != nil && lastDepUpdateStarted!.timeIntervalSinceNow > -120.0 {
            logger.log("Data is <2min old and force update is not specified, skipping...")
            return
        }
        guard let loc = location else {
            logger.error("Location not available")
            return
        }
        lastDepUpdateStarted = Date()
        logger.log("Updating departures with location \(self.locationString)...")
        await updateDeparturesHelper(loc: loc, configuration: configuration)
    }
    
    private func startUpdatingDepartures(secInterval: Double = 180.0) {
        Task {
            logger.log("DispatchQueue - updating departures")
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
//                updateManager.lastDepUpdateFinished = Date()
            } catch {
                updateManager.stnsDeps = []
            }
        } else {
            updateManager.stnsDeps = []
        }
        return updateManager
    }
}
