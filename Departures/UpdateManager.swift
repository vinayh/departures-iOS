//
//  Location.swift
//  Departures
//
//  Created by Vinay Hiremath on 2024-01-11.
//

import os
import SwiftUI
import CoreLocation

class WidgetUpdateManager: UpdateManager {
//    var hasUpdatedOnce = false
    
//    override func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
//        location = locations.last
//        reverseGeocode(loc: location)
//        Task {
//            let _: Bool = await updateDepartures(loc: location)
//            if !hasUpdatedOnce, success {
//                hasUpdatedOnce = true
//                WidgetCenter.shared.reloadTimelines(ofKind: "DeparturesWidget")
//                print("Reloading widget timelines")
//            }
//        }
//    }
}

class UpdateManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "UpdateManager")
    let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    private var locUpdateTask: Task<Bool, Error>? = nil
    lazy private var updater = Updater(stnsDeps: stnsDeps, dateDeparturesUpdated: dateDeparturesUpdated)
    private let geoloc_expiry_dist_m = 25.0
    
    @Published var updating = false
    @Published var location: CLLocation? = nil
    @Published var locationString: String = "Unknown"
    @Published var stnsDeps: [StationDepartures] = [StationDepartures]()
    @Published var dateDeparturesUpdated: Date? = nil
    @Published var dateDepartureUpdateAttempted: Date? = nil
    
    var updatedMinAgo: Int? { dateMinAgo(dateDeparturesUpdated) }
    var updateAttemptedMinAgo: Int? { dateMinAgo(dateDepartureUpdateAttempted) }
    
    func dateMinAgo(_ date: Date?) -> Int? {
        if let date {
            Int((Date().timeIntervalSince1970 - date.timeIntervalSince1970)/60)
        } else { nil }
    }
    
    enum Status {
        case initial
        case loaded(updatedMinAgo: Int, attemptedMinAgo: Int)
        case noResults(updatedMinAgo: Int, attemptedMinAgo: Int)
        case initFetching(attemptedMinAgo: Int)
        case loadedFetching(attemptedMinAgo: Int, updatedMinAgo: Int)
        case noResultsFetching(attemptedMinAgo: Int, updatedMinAgo: Int)
        case error
    }
    
    var status: Status {
        if updating, dateDepartureUpdateAttempted != nil {
            if dateDeparturesUpdated != nil {
                if stnsDeps.count > 0 { return Status.loadedFetching(attemptedMinAgo: updateAttemptedMinAgo!, updatedMinAgo: updatedMinAgo!) }
                else { return Status.noResultsFetching(attemptedMinAgo: updateAttemptedMinAgo!, updatedMinAgo: updatedMinAgo!) }
            } else { return Status.initFetching(attemptedMinAgo: updateAttemptedMinAgo!) }
        } else if !updating {
            if dateDeparturesUpdated != nil {
                if stnsDeps.count > 0 { return Status.loaded(updatedMinAgo: updatedMinAgo!, attemptedMinAgo: updateAttemptedMinAgo!) }
                else { return Status.noResults(updatedMinAgo: updatedMinAgo!, attemptedMinAgo: updateAttemptedMinAgo!) }
            } else if dateDepartureUpdateAttempted == nil { return Status.initial }
        }
        return Status.error
    }
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.distanceFilter = 300
        locationManager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let newLoc = locations.last, (location == nil || newLoc.distance(from: location!) > geoloc_expiry_dist_m) {
            reverseGeocode(loc: newLoc)
        }
        location = locations.last
        Task {
            logger.log("locationManager - updating departures")
            return await updateDepartures(force: false, loc: location)
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
            self.logger.log("Ran reverse geocode on \(self.locationString)")
            guard let postalCode = placemarks?.first?.postalCode else {
                self.logger.error("Reverse geocode error, locationString: \(self.locationString), error: \(error?.localizedDescription ?? "nil")")
                return
            }
            self.locationString = postalCode
        })
    }
    
    @MainActor
    func updateDepartures(force: Bool = false, configDictionary: Dictionary<String, Bool>? = nil, loc: CLLocation? = nil) async -> Bool {
        updating = true
        logger.log("updateDepartures - force: \(force), locationString: \(self.locationString)")
        dateDepartureUpdateAttempted = Date()
        do {
            let updatedData = try await updater.updated(location: loc ?? location,
                                                        force: force,
                                                        configDictionary: configDictionary)
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
    let cache_expiry_sec = 30.0
    let cache_expiry_dist_m = 100.0
    
    enum UpdaterError: LocalizedError {
        case locationError
        case fetchError
    }
    
    init(stnsDeps: [StationDepartures], dateDeparturesUpdated: Date?) {
        UserDefaults.standard.register(defaults: defaultSettings)
    }
    
    static func reqUrl(location: CLLocation, configDictionary: Dictionary<String, Bool>? = nil) -> URL {
        let baseUrl = "https://departures-backend.azurewebsites.net/api/nearest"
        func getKey(_ key: String) -> Bool {
            if let configDictionary { return configDictionary[key]! }
            else { return UserDefaults().object(forKey: key) as! Bool }
        }
        var modeTypes: [String] = []
        var stopTypes: [String] = []
        for m in ModeType.allCases {
            if getKey("mode.\(m.rawValue)") {
                modeTypes.append(m.rawValue)
            }
        }
        for s in StopType.allCases {
            if getKey("type.\(s.rawValue)") {
                stopTypes.append(s.rawValue)
            }
        }
        let urlString = "\(baseUrl)?lat=\(location.coordinate.latitude)&lng=\(location.coordinate.longitude)&stopTypes=\(stopTypes.joined(separator: ","))&modes=\(modeTypes.joined(separator: ","))"
        return URL(string: urlString)!
    }
    
    func cache(_ downloaded: SavedDepartures) {
        let encoded = try! JSONEncoder().encode(downloaded)
        UserDefaults(suiteName: "group.com.vinayh.Departures")!.set(encoded, forKey: "stnsDeps")
        logger.log("Caching fresh departures from: \(downloaded.date.formatted(date: .omitted, time: .shortened))")
    }
    
    func fromCache(location: CLLocation?) -> SavedDepartures? {
        let encoded = UserDefaults(suiteName: "group.com.vinayh.Departures")!.object(forKey: "stnsDeps") as? Data
        guard let encoded = encoded else {
            logger.log("Nothing saved in UserDefaults")
            return nil
        }
        guard let saved = try? JSONDecoder().decode(SavedDepartures.self, from: encoded) else {
            logger.error("Cannot decode SavedDepartures")
            return nil
        }
        if Date().timeIntervalSince1970 - saved.time < cache_expiry_sec {
            let prevLoc = CLLocation(latitude: CLLocationDegrees(saved.lat), longitude: CLLocationDegrees(saved.lng))
            if let newLoc = location, newLoc.distance(from: prevLoc) < cache_expiry_dist_m {
                logger.log("Retrieved cached departures, small loc change, time: \(saved.date.formatted(date: .omitted, time: .shortened))")
                return saved
            }
        }
        logger.log("Removing expired departures from: \(saved.date.formatted(date: .omitted, time: .shortened))")
        UserDefaults(suiteName: "group.com.vinayh.Departures")!.removeObject(forKey: "stnsDeps")
        return nil
    }
    
    func fetchDepartures(location: CLLocation?, force: Bool, configDictionary: Dictionary<String, Bool>?) async throws -> SavedDepartures {
        if !force, let cached = fromCache(location: location) {
            return cached
        }
        guard let location = location else {
            logger.error("Location not set")
            throw UpdaterError.locationError
        }
        logger.log("Fetching departures")
        let url = Updater.reqUrl(location: location, configDictionary: configDictionary)
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
    
    func updated(location: CLLocation?, force: Bool, configDictionary: Dictionary<String, Bool>?) async throws -> SavedDepartures {
        if let existingTask {
            return try await existingTask.value
        }
        let task = Task<SavedDepartures, Error> {
            existingTask = nil
            return try await fetchDepartures(location: location, force: force, configDictionary: configDictionary)
        }
        existingTask = task
        return try await task.value
    }
}
