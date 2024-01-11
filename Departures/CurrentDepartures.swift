//
//  StationDepartures.swift
//  Departures
//
//  Created by Vinay Hiremath on 2024-01-11.
//

import Foundation
import CoreLocation

struct Departure: Codable, Identifiable {
    let id: String
    let line: String
    let mode: String
    let destination: String
    let arrival_time: String
    
    func arrivingInMin() -> Int {
        let delta = ISO8601DateFormatter().date(from: arrival_time)!.timeIntervalSinceNow
        return Int((delta / 60).rounded(.down))
    }
    
    static func shortenDestName(_ dest: String) -> String {
        return dest
            .replacingOccurrences(of: " Underground Station", with: "")
            .replacingOccurrences(of: " Rail Station", with: "")
            .replacingOccurrences(of: " DLR Station", with: "")
    }
    
    static func formatLineName(_ line: String) -> String {
        let special = ["hammersmith-city": "H&C",
                       "dlr": "DLR"]
        if special.keys.contains(line) {
            return special[line]!
        } else {
            return line.capitalized
        }
    }
    
    static func example() -> Departure {
        let arrivalTimeString: String = Date.init(timeIntervalSinceNow: 500).ISO8601Format()
        return Departure(id: "test id", line: "New Tube", mode: "tube", destination: "Manchester", arrival_time: arrivalTimeString)
    }
}

struct Station: Codable, Identifiable {
    let id: String
    let lat: Float
    let lon: Float
    let name: String
    
    static func shortenStationName(_ station: String) -> String {
        return station
    //        .replacingOccurrences(of: "Underground Station", with: "🚇")
    //        .replacingOccurrences(of: "Rail Station", with: "🚆")
    //        .replacingOccurrences(of: "DLR Station", with: "🚈")
            .replacingOccurrences(of: "Underground Station", with: "")
            .replacingOccurrences(of: "Rail Station", with: "")
            .replacingOccurrences(of: "DLR Station", with: "")
    }
}

struct StationDepartures: Codable, Identifiable {
    let station: Station
    let departures: [Departure]
    
    var id: String {
        return station.id
    }
}

class CurrentDepartures: ObservableObject {
    @Published var stnsDeps: [StationDepartures]? = [StationDepartures]()
    @Published var lastUpdated: Date? = nil
    
    init(sample: Bool = true) {
        if sample {
            if let url = Bundle.main.url(forResource: "sampleDepartures", withExtension: "json") {
                do {
                    let jsonData = try Data(contentsOf: url)
                    stnsDeps = try JSONDecoder().decode([StationDepartures].self, from: jsonData)
                } catch {
                    stnsDeps = nil
                }
            } else {
                stnsDeps = nil
            }
        }
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
    
    func update(loc: CLLocation) async throws {
        let url = URL(string: CurrentDepartures.reqUrl(loc: loc))!
        let (data, _) = try await URLSession.shared.data(from: url) // Fetch JSON
        
        stnsDeps = try JSONDecoder().decode([StationDepartures].self, from: data) // Parse JSON
        lastUpdated = Date()
    }
}
