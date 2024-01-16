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

class UpdateManager: NSObject, ObservableObject, CLLocationManagerDelegate, URLSessionDelegate, URLSessionDataDelegate {
    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    private var lastDepUpdateStarted: Date? = nil
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "UpdateManager")
    private var receivedData: Data?
    var completion: (() -> Void)? = nil
    
    private var identifier: String
    private lazy var urlSession: URLSession = {
        let config = URLSessionConfiguration.background(withIdentifier: self.identifier)
        config.waitsForConnectivity = true
        return URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }()
    
    @Published var location: CLLocation? = nil
    @Published var locationString: String = "Unknown"
    @Published var stnsDeps: [StationDepartures] = [StationDepartures]()
    @Published var lastDepUpdateFinished: Date? = nil
    @Published var numCurrentlyUpdating: Int = 0
    
    init(identifier: String) {
        self.identifier = identifier
        super.init()
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 200
        locationManager.startUpdatingLocation()
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
        let baseUrl = "https://departures-backend.azurewebsites.net/api/nearest"
//        let baseUrl = "http://127.0.0.1:5000/nearest"
        let urlString = "\(baseUrl)?lat=\(loc.coordinate.latitude)&lng=\(loc.coordinate.longitude)&stopTypes=\(stopTypesString)"
        return URL(string: urlString)!
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping @Sendable (URLSession.ResponseDisposition) -> Void) {
        guard let response = response as? HTTPURLResponse,
              (200...299).contains(response.statusCode),
              let mimeType = response.mimeType,
              mimeType == "application/json"
        else {
            completionHandler(.cancel)
            return
        }
        completionHandler(.allow)
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        self.receivedData?.append(data)
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        DispatchQueue.main.async {
            self.numCurrentlyUpdating -= 1
            if let error = error {
                self.logger.error("Server error fetching departures, \(error)")
            }
            else if let data = self.receivedData {
                do {
                    let response = try JSONDecoder().decode(Response.self, from: data) // Parse JSON
                    self.stnsDeps = response.stnsDeps
                    self.lastDepUpdateFinished = Date()
                    self.logger.log("Finished updating departures for location \(self.locationString), station count: \(self.stnsDeps.count)")
                    Cache.store(stnsDeps: self.stnsDeps, date: self.lastDepUpdateFinished!)
                } catch {
                    self.logger.error("Error parsing departures, \(error)")
                }
            }
        }
    }
    
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        if session.configuration.identifier == "com.vinayh.Departures" {
//            self.numCurrentlyUpdating -= 1
        } else if session.configuration.identifier == "com.vinayh.Departures.DeparturesWidget" {
            logger.log("Reloading widget due to data update")
            WidgetCenter.shared.reloadAllTimelines()
            completion!()
        }
    }
    
    func update(loc: CLLocation, configuration: ConfigurationAppIntent? = nil) {
        self.numCurrentlyUpdating += 1
        let url = UpdateManager.reqUrl(loc: loc, configuration: configuration)
        receivedData = Data()
        let task = urlSession.dataTask(with: url)
        task.resume()
    }
    
    @MainActor
    func updateDepartures(force: Bool = false, configuration: ConfigurationAppIntent? = nil) {
        if !force {
            if let cache = Cache.retrieve() {
                stnsDeps = cache.stnsDeps
                lastDepUpdateStarted = Date(timeIntervalSince1970: cache.timeSince1970)
                return
            }
            if lastDepUpdateStarted != nil && lastDepUpdateStarted!.timeIntervalSinceNow > -120.0 {
                logger.log("Data is <2min old and force update is not specified, skipping...")
                return
            }
        }
        guard let loc = location else {
            logger.error("Location not available")
            return
        }
        logger.log("Updating departures with location \(self.locationString)...")
        update(loc: loc, configuration: configuration)
    }
    
    func startUpdatingDepartures(secInterval: Double = 180.0) {
        Task {
            logger.log("DispatchQueue - updating departures")
            await updateDepartures()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + secInterval) { [weak self] in
            self?.startUpdatingDepartures()
        }
    }
    
    static func example() -> UpdateManager {
        let updateManager = UpdateManager(identifier: "com.vinayh.Departures")
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

struct Cache: Codable {
    let stnsDeps: [StationDepartures]
    let timeSince1970: Double
    
    static func store(stnsDeps: [StationDepartures], date: Date) {
        let encoded = try! JSONEncoder().encode(Cache(stnsDeps: stnsDeps, timeSince1970: date.timeIntervalSince1970))
        UserDefaults(suiteName: "group.com.vinayh.Departures")!.set(encoded, forKey: "stnsDeps")
        print("Caching departures from date", date.formatted(date: .omitted, time: .shortened))
    }
    
    static func retrieve() -> Cache? {
        let encoded = UserDefaults(suiteName: "group.com.vinayh.Departures")!.object(forKey: "stnsDeps") as? Data
        if let encoded = encoded {
            if let cache = try? JSONDecoder().decode(Cache.self, from: encoded) {
                if Date().timeIntervalSince1970 - cache.timeSince1970 < 90.0 {
                    print("Retrieved departures from date", Date(timeIntervalSince1970: cache.timeSince1970).formatted(date: .omitted, time: .shortened))
                    return cache
                } else {
                    print("Removing departures from date", Date(timeIntervalSince1970: cache.timeSince1970).formatted(date: .omitted, time: .shortened))
                    UserDefaults(suiteName: "group.com.vinayh.Departures")!.removeObject(forKey: "stnsDeps")
                }
            }
        }
        return nil
    }
}
