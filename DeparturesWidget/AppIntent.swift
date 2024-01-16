//
//  AppIntent.swift
//  DeparturesWidget
//
//  Created by Vinay Hiremath on 2024-01-05.
//

import WidgetKit
import AppIntents

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Configuration"
    static var description = IntentDescription("This is an example widget.")

    @Parameter(title: "Underground, DLR", default: true)
    var metroStations: Bool
    
    @Parameter(title: "Rail, Overground", default: true)
    var railStations: Bool
    
    @Parameter(title: "Bus", default: false)
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
