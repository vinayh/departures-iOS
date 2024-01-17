//
//  Location.swift
//  Departures
//
//  Created by Vinay Hiremath on 2024-01-11.
//

import os
import SwiftUI
import WidgetKit
import CoreLocation

class WidgetUpdateManager: UpdateManager {
    var hasUpdatedOnce = false
    
    override func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locations.last
        reverseGeocode(loc: location)
        logger.log("locationManager - Widget updating departures")
        Task {
            let success: Bool = await updateDepartures(loc: location)
            print(success ? "locationManager - Widget successfully updated" : "locationManager - Widget update error")
            if !hasUpdatedOnce && success {
                hasUpdatedOnce = true
                WidgetCenter.shared.reloadTimelines(ofKind: "DeparturesWidget")
//                print("Reloading widget timelines")
            }
        }
    }
}

class UpdateManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "UpdateManager")
    private let updater = Updater()
    
    @Published var updating = false
    @Published var location: CLLocation? = nil
    @Published var locationString: String = "Unknown"
    @Published var stnsDeps: [StationDepartures] = [StationDepartures]()
    @Published var dateDeparturesUpdated: Date? = nil
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.distanceFilter = 500
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locations.last
        reverseGeocode(loc: location)
        logger.log("locationManager - updating departures")
        Task {
            await updateDepartures(loc: location)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        location = nil
        locationString = "Error"
        logger.error("\(error)")
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
    
    func reverseGeocode(loc: CLLocation?) {
        guard let loc = loc else {
            locationString = "Unavailable"
            return
        }
        locationString = String(format: "[%.2f, %.2f]", loc.coordinate.latitude, loc.coordinate.longitude)
        geocoder.reverseGeocodeLocation(loc, completionHandler: {(placemarks, error) -> Void in
            if let postalCode = placemarks?.first?.postalCode {
                self.locationString = postalCode
            }
        })
    }
    
    @MainActor
    func updateDepartures(force: Bool = false, configuration: ConfigurationAppIntent? = nil, loc: CLLocation? = nil) async -> Bool {
        logger.log("Updating departures, current locationString: \(self.locationString)")
        if !updating {
            updating = true
            let updatedData: SavedDepartures? = await updater.departures(location: loc ?? location, force: force, configuration: configuration)
            if let updatedData {
                stnsDeps = updatedData.stnsDeps
                dateDeparturesUpdated = updatedData.date
            }
            updating = false
            return updatedData != nil
        } else {
            logger.log("---Already running elsewhere")
            return true
        }
    }
    
//    func scheduleIntervalUpdates(secInterval: Int = 180) {
//        Task {
//            logger.log("DispatchQueue - updating departures")
//            await updateDepartures()
//        }
//        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(secInterval)) { [weak self] in
//            self?.scheduleIntervalUpdates()
//        }
//    }
    
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

struct SavedDepartures: Codable {
    let stnsDeps: [StationDepartures]
    let time: Double
    let lat: Float
    let lng: Float
    var date: Date { Date(timeIntervalSince1970: time) }
}

actor Updater {
    let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "Updater")
    var lastDepUpdateStarted: Date? = nil
    var lastDepUpdateFinished: Date? = nil
    var downloading: Bool = false
    
    static func reqUrl(location: CLLocation, configuration: ConfigurationAppIntent? = nil) -> URL {
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
        
        let baseUrl = "https://departures-backend.azurewebsites.net/api/nearest"
//        let baseUrl = "http://127.0.0.1:5000/nearest"
        let urlString = "\(baseUrl)?lat=\(location.coordinate.latitude)&lng=\(location.coordinate.longitude)&stopTypes=\(stopTypesString)"
        return URL(string: urlString)!
    }
    
    func cache(_ downloaded: SavedDepartures) {
        let encoded = try! JSONEncoder().encode(downloaded)
        UserDefaults(suiteName: "group.com.vinayh.Departures")!.set(encoded, forKey: "stnsDeps")
        print("Caching fresh departures from:", downloaded.date.formatted(date: .omitted, time: .shortened))
    }
    
    func fromCache() -> SavedDepartures? {
        let expiry_sec = 30.0
        let encoded = UserDefaults(suiteName: "group.com.vinayh.Departures")!.object(forKey: "stnsDeps") as? Data
        if let encoded = encoded {
            if let saved = try? JSONDecoder().decode(SavedDepartures.self, from: encoded) {
                if Date().timeIntervalSince1970 - saved.time < expiry_sec {
                    print("Retrieved departures from:", saved.date.formatted(date: .omitted, time: .shortened))
                    return saved
                } else {
                    print("Removing expired departures from:", saved.date.formatted(date: .omitted, time: .shortened))
                    UserDefaults(suiteName: "group.com.vinayh.Departures")!.removeObject(forKey: "stnsDeps")
                }
            } else {
                print("Cannot decode SavedDepartures")
            }
        } else {
            print("Nothing saved in UserDefaults")
        }
        return nil
    }
    
    func departures(location: CLLocation?, force: Bool, configuration: ConfigurationAppIntent?) async -> SavedDepartures? {
        if !force, let cached = fromCache() {
            return cached
        } else {
            guard let location = location else {
                print("Location not set")
                return nil
            }
            let url = Updater.reqUrl(location: location, configuration: configuration)
            downloading = true
            let task = Task {
                let (data, _) = try await URLSession.shared.data(from: url) // Fetch JSON
                return try JSONDecoder().decode(Response.self, from: data) // Parse JSON
            }
            do {
                let response = try await task.value
                downloading = false
                let downloaded = SavedDepartures(stnsDeps: response.stnsDeps,
                                            time: Date().timeIntervalSince1970,
                                            lat: Float(location.coordinate.latitude),
                                            lng: Float(location.coordinate.longitude))
                cache(downloaded)
                return downloaded
            } catch {
                downloading = false
                logger.error("Error fetching departures, req URL: \(url.absoluteString), error: \(error)")
                lastDepUpdateStarted = nil
                return nil
            }
        }
    }
}
