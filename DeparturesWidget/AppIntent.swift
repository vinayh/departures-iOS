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
    var busStops: Bool
    
    @Parameter(title: "Underground", default: true)
    var modeTube: Bool
    
    @Parameter(title: "DLR", default: true)
    var modeDlr: Bool
    
    @Parameter(title: "Overground", default: true)
    var modeOverground: Bool
    
    @Parameter(title: "Elizabeth line", default: true)
    var modeElizabeth: Bool
    
    @Parameter(title: "Bus", default: false)
    var modeBus: Bool
    
    @Parameter(title: "Tram", default: false)
    var modeTram: Bool
}

#if DEBUG
extension ConfigurationAppIntent {
    static var example: ConfigurationAppIntent {
        let intent = ConfigurationAppIntent()
        intent.metroStations = true
        intent.railStations = true
        intent.busStops = false
        intent.modeTube = true
        intent.modeDlr = true
        intent.modeOverground = true
        intent.modeElizabeth = true
        intent.modeBus = false
        intent.modeTram = false
        return intent
    }
}
#endif
