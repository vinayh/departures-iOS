//
//  AppIntent.swift
//  DeparturesWidget
//
//  Created by Vinay Hiremath on 2024-01-05.
//

import WidgetKit
import AppIntents

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Departures"
    static var description = IntentDescription("Choose the types of stations/stops to be displayed.")

    @Parameter(title: "Underground and DLR", default: true)
    var metroStations: Bool
    
    @Parameter(title: "Elizabeth Line and Overground", default: true)
    var railStations: Bool
    
    @Parameter(title: "Bus and Tram", default: false)
    var busStations: Bool
}

#if DEBUG
extension ConfigurationAppIntent {
    static var example: ConfigurationAppIntent {
        let intent = ConfigurationAppIntent()
        intent.metroStations = true
        intent.railStations = true
        intent.busStations = false
        return intent
    }
}
#endif
