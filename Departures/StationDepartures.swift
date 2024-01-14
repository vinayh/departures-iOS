//
//  StationDepartures.swift
//  Departures
//
//  Created by Vinay Hiremath on 2024-01-11.
//

import SwiftUI
import CoreLocation


struct Departure: Codable, Identifiable, Equatable {
    let id: String
    let line: String
    let mode: String
    let destination: String
    let arrival_time: String

    var backgroundColor: Color {
        return Color(line)
    }
    
    func foregroundColor(_ environment: EnvironmentValues) -> Color {
        let resolved = backgroundColor.resolve(in: environment)
        let luminance = 0.2126 * resolved.red + 0.7152 * resolved.green + 0.0722 * resolved.green
        return luminance < 0.6 ? .white : .black
    }
    
    func arrivingInMin() -> Int {
        let arrivalDate = ISO8601DateFormatter().date(from: arrival_time)!
        return Int((arrivalDate.timeIntervalSinceNow / 60).rounded(.down))
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
    
    static func == (lhs: Departure, rhs: Departure) -> Bool {
        return lhs.destination == rhs.destination && lhs.line == rhs.line
    }
    
    static func example() -> Departure {
        let arrivalTimeString: String = Date.init(timeIntervalSinceNow: 500).ISO8601Format()
        return Departure(id: "test id", line: "New Tube", mode: "tube", destination: "Manchester", arrival_time: arrivalTimeString)
    }
}

struct Station: Codable, Identifiable, Equatable {
    let id: String
    let lat: Float
    let lon: Float
    let name: String
    
    var nameShort: String {
        return name
        //        .replacingOccurrences(of: "Underground Station", with: "🚇")
        //        .replacingOccurrences(of: "Rail Station", with: "🚆")
        //        .replacingOccurrences(of: "DLR Station", with: "🚈")
            .replacingOccurrences(of: "Underground Station", with: "")
            .replacingOccurrences(of: "Rail Station", with: "")
            .replacingOccurrences(of: "DLR Station", with: "")
    }
    
    static func == (lhs: Station, rhs: Station) -> Bool {
        return lhs.id == rhs.id
    }
}

struct StationDepartures: Codable, Identifiable, Equatable {
    let station: Station
    let departures: [Departure]
    
    var id: String {
        return station.id
    }
    
    var mergedDepartures: [[Departure]] {
        func uniqueRouteKey(_ dep: Departure) -> String {
            return "\(dep.destination)%\(dep.line)"
        }
        
        var out: [[Departure]] = []
        var destinationsSeen: [String: Int] = [:]
        
        for d in departures {
            if let idx = destinationsSeen[uniqueRouteKey(d)] {
                out[idx].append(d)
            } else {
                destinationsSeen[uniqueRouteKey(d)] = out.endIndex
                out.append([d])
            }
        }
        return out
    }
    
    static func == (lhs: StationDepartures, rhs: StationDepartures) -> Bool {
        return lhs.station == rhs.station && lhs.departures == rhs.departures
    }
}
