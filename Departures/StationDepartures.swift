//
//  StationDepartures.swift
//  Departures
//
//  Created by Vinay Hiremath on 2024-01-11.
//

import SwiftUI


struct Departure: Codable, Identifiable, Equatable, Hashable {
    let id: String
    let line: String
    let mode: String
    let destination: String
    let arrival_time: String
    
    var destinationShort: String {
        return destination
            .replacingOccurrences(of: " Underground Station", with: "")
            .replacingOccurrences(of: " Rail Station", with: "")
            .replacingOccurrences(of: " DLR Station", with: "")
    }
    
    var lineFormatted: String {
        let special = ["hammersmith-city": "H&C",
                       "london-overground": "Overground",
                       "dlr": "DLR"]
        return special[line] ?? line.capitalized
    }
    
    var arrivingInMin: Int {
        let arrivalDate = ISO8601DateFormatter().date(from: arrival_time)!
        return Int((arrivalDate.timeIntervalSinceNow / 60).rounded(.down))
    }
    
    var backgroundColor: Color { Color(line) }
    
    func foregroundColor(_ environment: EnvironmentValues) -> Color {
        let resolved = backgroundColor.resolve(in: environment)
        let luminance = 0.2126 * resolved.red + 0.7152 * resolved.green + 0.0722 * resolved.green
        return luminance < 0.6 ? .white : .black
    }

    // TODO: Check if this Equatable impl prevents UI data from updating if destination/line remain the same and only arrival_time changes
    // Now added arrival_time comparison to StationDepartures equality function to hopefully prevent this possible issue
    static func == (lhs: Departure, rhs: Departure) -> Bool {
        return lhs.destination == rhs.destination && lhs.line == rhs.line
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(destination)
        hasher.combine(line)
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
    
    var id: String { station.id }
    
    var mergedDepartures: [[Departure]] {
        var out: [[Departure]] = []
        var destinationsSeen: [Departure: Int] = [:]
        
        for d in departures {
            if let idx = destinationsSeen[d] {
                out[idx].append(d)
            } else {
                destinationsSeen[d] = out.endIndex
                out.append([d])
            }
        }
        return out
    }
    
    static func == (lhs: StationDepartures, rhs: StationDepartures) -> Bool {
        return lhs.station == rhs.station
        && lhs.departures == rhs.departures
        && lhs.departures.map { dep in dep.arrival_time } == rhs.departures.map { dep in dep.arrival_time }
    }
}

struct Response: Codable {
    let stnsDeps: [StationDepartures]
    let lat: Float
    let lng: Float
}

