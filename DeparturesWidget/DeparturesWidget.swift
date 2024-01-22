//
//  DeparturesWidget.swift
//  DeparturesWidget
//
//  Created by Vinay Hiremath on 2024-01-05.
//

import WidgetKit
import SwiftUI

struct DeparturesEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationAppIntent
    let locString: String
    let dateDeparturesUpdated: Date?
    let stnsDeps: [StationDepartures]?
}

struct DeparturesWidgetEntryView : View {
    var entry: DeparturesEntry
    
    @Environment(\.widgetFamily)
    private var family
    
    private var numStations: Int {
        return [WidgetFamily.accessoryRectangular: 4,
                WidgetFamily.systemMedium: 6,
                WidgetFamily.systemLarge: 8][family] ?? 6
    }
    
    private var numDeps: Int {
        return [WidgetFamily.accessoryRectangular: 2,
                WidgetFamily.systemMedium: 3,
                WidgetFamily.systemLarge: 4][family] ?? 3
    }
    
    private var textSizeStn: CGFloat {
        return (CGFloat)([WidgetFamily.accessoryRectangular: 8,
                WidgetFamily.systemMedium: 10,
                WidgetFamily.systemLarge: 12][family] ?? 8)
    }
    
    private var textSizeDep: CGFloat {
        return (CGFloat)([WidgetFamily.accessoryRectangular: 7,
                WidgetFamily.systemMedium: 8,
                WidgetFamily.systemLarge: 9][family] ?? 6)
    }
    
    private func renderStnDeps(_ stnDeps: StationDepartures) -> AnyView {
        let numDeps: Int = numDeps
        
        return AnyView(Grid(horizontalSpacing: 3) {
            Text(stnDeps.station.nameShort)
                .frame(maxWidth: .infinity, alignment: .leading)
                .font(.system(size: textSizeStn))
                .lineLimit(1)
            
            ForEach(stnDeps.departures.indices.prefix(numDeps), id: \.self) { index in
                let dep = stnDeps.departures[index]
                GridRow {
                    Text("\(dep.arrivingInMin)'")
                        .bold()
                    if family == .accessoryRectangular {
                        Text("\(dep.destinationShort) - \(dep.lineFormatted)")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        Text("\(dep.destinationShort) - \(dep.lineFormatted)")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .underline(color: dep.backgroundColor)
                    }
                }
                .font(.system(size: textSizeDep))
                .lineLimit(1)
            }
        })
    }
    
    var body: some View {
        let stopTypes: String = (entry.configuration.metroStations ? "🚇" : "")
        + (entry.configuration.railStations ? "🚆" : "")
        + (entry.configuration.busStops ? "🚌" : "")
        
        // TODO: Improve text adaptation to widget type/size, currently works passably for small and medium widgets
        VStack(spacing: 0) {
            HStack {
                Text("Updated: \(entry.dateDeparturesUpdated?.formatted(date: .omitted, time: .shortened) ?? "Error")")
                Text(entry.locString)
                Text(stopTypes)
            }
            .font(.system(size: 6))
            
            if entry.stnsDeps != nil {
                let columns = [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ]
                
                LazyVGrid(columns: columns, spacing: 0) {
                    ForEach(entry.stnsDeps!.indices.prefix(numStations), id: \.self) { index in
                        VStack {
                            renderStnDeps(entry.stnsDeps![index])
                            Divider()
                        }
                    }
                }
            }
            else {
                Text("Unable to fetch stations")
                    .font(.system(size: 10))
            }
        }
    }
}

struct DeparturesTimelineProvider: AppIntentTimelineProvider {
    typealias Entry = DeparturesEntry
    typealias Intent = ConfigurationAppIntent
    var updateManager: WidgetUpdateManager
    
    init(_ manager: WidgetUpdateManager) {
        updateManager = manager
    }
    
    func placeholder(in context: Context) -> DeparturesEntry {
        return DeparturesEntry(date: Date(),
                               configuration: ConfigurationAppIntent(),
                               locString: updateManager.locationString,
                               dateDeparturesUpdated: Date(),
                               stnsDeps: UpdateManager.example().stnsDeps)
    }
    
    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> DeparturesEntry {
        let entry = DeparturesEntry(date: Date(),
                                    configuration: ConfigurationAppIntent(),
                                    locString: updateManager.locationString,
                                    dateDeparturesUpdated: Date(),
                                    stnsDeps: UpdateManager.example().stnsDeps)
        return entry
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<DeparturesEntry> {
//        print("timeline - Widget updating")
        _ = await updateManager.updateDepartures(configDictionary: DeparturesTimelineProvider.configDictionary(configuration))
//        print(updatedData != nil ? "timeline - Widget successfully updated" : "timeline - Widget update error")
        let entry: DeparturesEntry = DeparturesEntry(date: updateManager.dateDeparturesUpdated ?? Date(),
                                                     configuration: configuration,
                                                     locString: updateManager.locationString,
                                                     dateDeparturesUpdated: updateManager.dateDeparturesUpdated,
                                                     stnsDeps: updateManager.stnsDeps)
        let nextUpdate = Calendar.current.date(byAdding: DateComponents(minute: 5), to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        return timeline
    }
    
    static func configDictionary(_ cfg: ConfigurationAppIntent) -> Dictionary<String, Bool> {
        var cfgDict: [String: Bool] = [:]
        cfgDict["mode.NaptanMetroStation"] = cfg.metroStations
        cfgDict["mode.NaptanRailStation"] = cfg.railStations
        cfgDict["mode.NaptanPublicBusCoachTram"] = cfg.busStops
        cfgDict["type.tube"] = cfg.modeTube
        cfgDict["type.dlr"] = cfg.modeDlr
        cfgDict["type.overground"] = cfg.modeOverground
        cfgDict["type.elizabeth-line"] = cfg.modeElizabeth
        cfgDict["type.bus"] = cfg.modeBus
        cfgDict["type.tram"] = cfg.modeTram
        return cfgDict
    }
}

struct DeparturesWidget: Widget {
    let kind: String = "DeparturesWidget"
    let updateManager = WidgetUpdateManager()
    
    var body: some WidgetConfiguration {
        return AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: DeparturesTimelineProvider(updateManager)) { entry in
            DeparturesWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Departures")
        .description("View upcoming TfL departures near your location.")
        .supportedFamilies([.accessoryRectangular, .systemMedium])
    }
}

#Preview(as: .systemMedium) {
    DeparturesWidget()
} timeline: {
    DeparturesEntry(date: .now, configuration: .example, locString: "PREVIEW LOC", dateDeparturesUpdated: .now, stnsDeps: UpdateManager.example().stnsDeps)
//    let updateManager = UpdateManager()
//    DeparturesEntry(date: .now, configuration: .example, locString: updateManager.locationString, stnsDeps: updateManager.stnsDeps)
}
