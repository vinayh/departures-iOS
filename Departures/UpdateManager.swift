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
        location = locations.last
        reverseGeocode(loc: location)
        //        logger.log("locationManager - Widget updating departures")
        Task {
            let success: Bool = await updateDepartures(loc: location)
            //            print(success ? "locationManager - Widget successfully updated" : "locationManager - Widget update error")
            if !hasUpdatedOnce && success {
                hasUpdatedOnce = true
                WidgetCenter.shared.reloadTimelines(ofKind: "DeparturesWidget")
                //                print("Reloading widget timelines")
            }
        }
    }
}

class UpdateManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "UpdateManager")
    let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    private var locUpdateTask: Task<Bool, Error>? = nil
    lazy private var updater = Updater(stnsDeps: stnsDeps, dateDeparturesUpdated: dateDeparturesUpdated)
    
    @Published var updating = false
    @Published var location: CLLocation? = nil
    @Published var locationString: String = "Unknown"
    @Published var stnsDeps: [StationDepartures] = [StationDepartures]()
    @Published var dateDeparturesUpdated: Date? = nil
    @Published var dateDepartureUpdateAttempted: Date? = nil
    
    
    func dateMinAgo(_ date: Date?) -> Int? {
        if let date {
            Int((Date().timeIntervalSince1970 - date.timeIntervalSince1970)/60)
        } else { nil }
    }
    var updatedMinAgo: Int? { dateMinAgo(dateDeparturesUpdated) }
    var updateAttemptedMinAgo: Int? { dateMinAgo(dateDepartureUpdateAttempted) }
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.distanceFilter = 300
        locationManager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        func updateTask(_ force: Bool) {
            Task {
                logger.log("locationManager - updating departures, force: \(force)")
                return await updateDepartures(force: force, loc: location)
            }
        }
        var forceUpdate = location == nil
        if let prevLoc = location, let newLoc = locations.last, prevLoc.distance(from: newLoc) > 200 {
            logger.log("locationManager - location change \(prevLoc.distance(from: newLoc) > 200)")
            forceUpdate = true
        }
        location = locations.last
        reverseGeocode(loc: location)
        updateTask(forceUpdate)
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
        updating = true
        logger.log("updateDepartures - force: \(force), locationString: \(self.locationString)")
        dateDepartureUpdateAttempted = Date()
        do {
            let updatedData = try await updater.updated(location: loc ?? location,
                                                           force: force,
                                                           configuration: configuration)
            stnsDeps = updatedData.stnsDeps
            dateDeparturesUpdated = updatedData.date
            updating = await updater.existingTask != nil
            return true
        } catch {
            logger.error("updateDepartures - Error fetching departures: \(error)")
            updating = await updater.existingTask != nil
            return false
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
        updateManager.dateDeparturesUpdated = Date()
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
    var existingTask: Task<SavedDepartures, Error>?
    
    let defaultSettings = ["type.NaptanMetroStation": true,
                           "type.NaptanRailStation": true,
                           "type.NaptanPublicBusCoachTram": false,
                           "mode.tube": true,
                           "mode.dlr": true,
                           "mode.overground": true,
                           "mode.elizabeth-line": true,
                           "mode.bus": false,
                           "mode.tram": false
    ]
    
    enum UpdaterError: LocalizedError {
        case locationError
        case fetchError
    }
    
    init(stnsDeps: [StationDepartures], dateDeparturesUpdated: Date?) {
        UserDefaults.standard.register(defaults: defaultSettings)
    }
    
    static func reqUrl(location: CLLocation, configuration: ConfigurationAppIntent? = nil) -> URL {
        //        TODO: Use stop types preferences for main app
        let baseUrl = "https://departures-backend.azurewebsites.net/api/nearest"
        //        let baseUrl = "http://127.0.0.1:5000/nearest"
        if let cfg = configuration {
            var stopTypes: [String] = []
            if cfg.metroStations { stopTypes.append("NaptanMetroStation") }
            if cfg.railStations { stopTypes.append("NaptanRailStation") }
            if cfg.busStations { stopTypes.append("NaptanPublicBusCoachTram") }
            let urlString = "\(baseUrl)?lat=\(location.coordinate.latitude)&lng=\(location.coordinate.longitude)&stopTypes=\(stopTypes.joined(separator: ","))"
            return URL(string: urlString)!
        }
        else {
            var modeTypes: [String] = []
            var stopTypes: [String] = []
            for m in ModeType.allCases {
                if UserDefaults().object(forKey: "mode.\(m.rawValue)") as! Bool {
                    modeTypes.append(m.rawValue)
                }
            }
            for s in StopType.allCases {
                if UserDefaults().object(forKey: "type.\(s.rawValue)") as! Bool {
                    stopTypes.append(s.rawValue)
                }
            }
            let urlString = "\(baseUrl)?lat=\(location.coordinate.latitude)&lng=\(location.coordinate.longitude)&stopTypes=\(stopTypes.joined(separator: ","))&modes=\(modeTypes.joined(separator: ","))"
            return URL(string: urlString)!
        }
    }
    
    func cache(_ downloaded: SavedDepartures) {
        let encoded = try! JSONEncoder().encode(downloaded)
        UserDefaults(suiteName: "group.com.vinayh.Departures")!.set(encoded, forKey: "stnsDeps")
        logger.log("Caching fresh departures from: \(downloaded.date.formatted(date: .omitted, time: .shortened))")
    }
    
    func fromCache() -> SavedDepartures? {
        let expiry_sec = 30.0
        let encoded = UserDefaults(suiteName: "group.com.vinayh.Departures")!.object(forKey: "stnsDeps") as? Data
        guard let encoded = encoded else {
            logger.log("Nothing saved in UserDefaults")
            return nil
        }
        guard let saved = try? JSONDecoder().decode(SavedDepartures.self, from: encoded) else {
            logger.error("Cannot decode SavedDepartures")
            return nil
        }
        if Date().timeIntervalSince1970 - saved.time < expiry_sec {
            logger.log("Retrieved departures from: \(saved.date.formatted(date: .omitted, time: .shortened))")
            return saved
        } else {
            logger.log("Removing expired departures from: \(saved.date.formatted(date: .omitted, time: .shortened))")
            UserDefaults(suiteName: "group.com.vinayh.Departures")!.removeObject(forKey: "stnsDeps")
            return nil
        }
    }
    
    func fetchDepartures(location: CLLocation?, force: Bool, configuration: ConfigurationAppIntent?) async throws -> SavedDepartures {
        if !force, let cached = fromCache() {
            return cached
        }
        guard let location = location else {
            logger.error("Location not set")
            throw UpdaterError.locationError
        }
        logger.log("Fetching departures")
        let url = Updater.reqUrl(location: location, configuration: configuration)
        let task = Task {
            let (data, _) = try await URLSession.shared.data(from: url) // Fetch JSON
            return try JSONDecoder().decode(Response.self, from: data) // Parse JSON
        }
        do {
            let response = try await task.value
            let downloaded = SavedDepartures(stnsDeps: response.stnsDeps,
                                             time: Date().timeIntervalSince1970,
                                             lat: Float(location.coordinate.latitude),
                                             lng: Float(location.coordinate.longitude))
            cache(downloaded)
            return downloaded
        } catch {
            logger.error("Error fetching departures, req URL: \(url.absoluteString), error: \(error)")
            throw UpdaterError.fetchError
        }
    }
    
    func updated(location: CLLocation?, force: Bool, configuration: ConfigurationAppIntent?) async throws -> SavedDepartures {
        if let existingTask {
            return try await existingTask.value
        }
        let task = Task<SavedDepartures, Error> {
            existingTask = nil
            return try await fetchDepartures(location: location, force: force, configuration: configuration)
        }
        existingTask = task
        return try await task.value
    }
}
