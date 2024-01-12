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
    
    #if DEBUG
    static func example() -> Departure {
        let arrivalTimeString: String = Date.init(timeIntervalSinceNow: 500).ISO8601Format()
        return Departure(id: "test id", line: "New Tube", mode: "tube", destination: "Manchester", arrival_time: arrivalTimeString)
    }
    #endif
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
}
