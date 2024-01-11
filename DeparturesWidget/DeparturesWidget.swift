//
//  DeparturesWidget.swift
//  DeparturesWidget
//
//  Created by Vinay Hiremath on 2024-01-05.
//

import WidgetKit
import SwiftUI
import CoreLocation


func getSampleStnsDeps() -> [StationDepartures]? {
    if let url = Bundle.main.url(forResource: "sampleDepartures", withExtension: "json") {
        do {
            let jsonData = try Data(contentsOf: url)
            return try? JSONDecoder().decode([StationDepartures].self, from: jsonData)
        } catch {
            return nil
        }
    }
    return nil
}

func shortenStationName(_ station: String) -> String {
    return station
//        .replacingOccurrences(of: "Underground Station", with: "🚇")
//        .replacingOccurrences(of: "Rail Station", with: "🚆")
//        .replacingOccurrences(of: "DLR Station", with: "🚈")
        .replacingOccurrences(of: " Underground Station", with: "")
        .replacingOccurrences(of: " Rail Station", with: "")
        .replacingOccurrences(of: " DLR Station", with: "")
}

func formatLineName(_ line: String) -> String {
    let special = ["hammersmith-city": "H&C",
                   "dlr": "DLR"]
    if special.keys.contains(line) {
        return special[line]!
    } else {
        return line.capitalized
    }
}

func shortenDestName(_ dest: String) -> String {
    return dest
        .deleteSuffix(" Underground Station")
        .deleteSuffix(" Rail Station")
        .replacingOccurrences(of: "DLR Station", with: "DLR")
}

struct Departure: Codable {
    let id: String
    let line: String
    let mode: String
    let destination: String
    let arrival_time: String
    
    func arrivingInMin() -> Int {
        let delta = ISO8601DateFormatter().date(from: arrival_time)!.timeIntervalSinceNow
        return Int((delta / 60).rounded(.down))
    }
}

struct Station: Codable {
    let id: String
    let lat: Float
    let lon: Float
    let name: String
}

struct StationDepartures: Codable {
    let station: Station
    let departures: [Departure]
}

class LocationManager: NSObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    @Published var location: CLLocation? = CLLocation(latitude: 51.5072, longitude: -0.1276)
    @Published var locationString: String = "Loc unknown"
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        location = locations.first
        updateLocationString(location)
    }
    
    private func updateLocationString(_ location: CLLocation?) {
        guard let location = location else {
            locationString = "Loc unavailable"
            return
        }
        locationString = String(format: "[%.2f, %.2f]", location.coordinate.latitude, location.coordinate.longitude)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        location = nil
        locationString = "Loc error: \(error.localizedDescription)"
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:  // Location services are available.
            locationManager.startUpdatingLocation()
            break
        case .restricted, .denied:  // Location services currently unavailable.
            locationString = "Loc access denied"
            break
        case .notDetermined:        // Authorization not determined yet.
            manager.requestAlwaysAuthorization()
            break
        default:
            break
        }
    }
    
}

struct DeparturesEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationAppIntent
    let locString: String
    let stnsDeps: [StationDepartures]?
}

struct DeparturesWidgetEntryView : View {
    var entry: DeparturesEntry
    
    @Environment(\.widgetFamily)
    var family
    
    let familyToNumStations = [WidgetFamily.accessoryRectangular: 4,
                               WidgetFamily.systemMedium: 6,
                               WidgetFamily.systemLarge: 8]
    
    let familyToNumDeps = [WidgetFamily.accessoryRectangular: 2,
                           WidgetFamily.systemMedium: 3,
                           WidgetFamily.systemLarge: 4]
    
    let textSizeStn = [WidgetFamily.accessoryRectangular: 8,
                       WidgetFamily.systemMedium: 10,
                       WidgetFamily.systemLarge: 12]
    
    let textSizeDep = [WidgetFamily.accessoryRectangular: 7,
                       WidgetFamily.systemMedium: 8,
                       WidgetFamily.systemLarge: 9]
    
    private func renderStnDeps(_ stnDeps: StationDepartures) -> AnyView {
        let numDeps: Int = familyToNumDeps[family] ?? 3
        
        return AnyView(Grid(horizontalSpacing: 3) {
            Text(shortenStationName(stnDeps.station.name))
                .frame(maxWidth: .infinity, alignment: .leading)
                .font(.system(size: (CGFloat)(textSizeStn[family] ?? 8)))
                .lineLimit(1)
            
            ForEach(stnDeps.departures.indices.prefix(numDeps), id: \.self) { index in
                let dep = stnDeps.departures[index]
                GridRow {
                    Text("\(dep.arrivingInMin())'")
                        .bold()
                    if family == .accessoryRectangular {
                        Text("\(shortenDestName(dep.destination)) - \(formatLineName(dep.line))")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        Text("\(shortenDestName(dep.destination)) - \(formatLineName(dep.line))")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .underline(color: Color(dep.line))
                    }
                }
                .font(.system(size: (CGFloat)(textSizeDep[family] ?? 6)))
                .lineLimit(1)
            }
        })
    }
    
    var body: some View {
        let stopTypes: String = (entry.configuration.metroStations ? "🚇" : "")
            + (entry.configuration.railStations ? "🚆" : "")
            + (entry.configuration.busStations ? "🚌" : "")
        
        let numStations: Int = familyToNumStations[family] ?? 6
        
        // TODO: Improve text adaptation to widget type/size, currently works passably for small and medium widgets
        VStack(spacing: 0) {
            HStack {
                Text("Updated: \(entry.date.formatted(date: .omitted, time: .shortened))")
                    .font(.system(size: 6))
                
                Text(entry.locString)
                    .font(.system(size: 6))
                
                Text(stopTypes)
                    .font(.system(size: 6))
            }
            
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

struct DeparturesFetcher {
    enum DepartureFetcherError: Error {
        case departureDataCorrupted
    }
    
    private static func reqUrl(loc: CLLocation, configuration: ConfigurationAppIntent) -> String {
        var stopTypes: [String] = []
        if configuration.metroStations {
            stopTypes.append("NaptanMetroStation")
        }
        if configuration.railStations {
            stopTypes.append("NaptanRailStation")
        }
        if configuration.busStations {
            stopTypes.append("NaptanPublicBusCoachTram")
        }
        let stopTypesString = stopTypes.joined(separator: ",")
        return "https://departures-backend.azurewebsites.net/api/nearest?lat=\(loc.coordinate.latitude)&lng=\(loc.coordinate.longitude)&stopTypes=\(stopTypesString)"
    }
    
    static func fetchDepartures(loc: CLLocation, configuration: ConfigurationAppIntent) async throws -> [StationDepartures] {
        let url = URL(string: reqUrl(loc: loc, configuration: configuration))!
        
        // Fetch JSON
        let (data, _) = try await URLSession.shared.data(from: url)
        
        // Parse JSON
        let stnsDeps = try JSONDecoder().decode([StationDepartures].self, from: data)

        return stnsDeps
    }
}


struct DeparturesTimelineProvider: AppIntentTimelineProvider {
    typealias Entry = DeparturesEntry
    typealias Intent = ConfigurationAppIntent
    var locationManager = LocationManager()
    
    func placeholder(in context: Context) -> DeparturesEntry {
        return DeparturesEntry(date: Date(),
                               configuration: ConfigurationAppIntent(),
                               locString: locationManager.locationString,
                               stnsDeps: getSampleStnsDeps()!)
    }
    
    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> DeparturesEntry {
        let snapshotDepartures: ConfigurationAppIntent
        
//        if context.isPreview && !DeparturesFetcher.cachedDeparturesAvailable {
//            snapshotDepartures = ConfigurationAppIntent() // If not cached
//        } else {
        snapshotDepartures = ConfigurationAppIntent() // TODO: Otherwise use cached
//        }
        let entry = DeparturesEntry(date: Date(),
                                    configuration: snapshotDepartures,
                                    locString: locationManager.locationString,
                                    stnsDeps: getSampleStnsDeps()!)
        return entry
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<DeparturesEntry> {
        let loc = locationManager.location
        let stnsDeps: [StationDepartures]? = (loc != nil) ? try? await DeparturesFetcher.fetchDepartures(loc: loc!, configuration: configuration) : nil
        let entry: DeparturesEntry = DeparturesEntry(date: Date(),
                                                     configuration: ConfigurationAppIntent(),
                                                     locString: locationManager.locationString,
                                                     stnsDeps: stnsDeps)
        let nextUpdate = Calendar.current.date(byAdding: DateComponents(minute: 5), to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        return timeline
    }
}



struct DeparturesWidget: Widget {
    let kind: String = "DeparturesWidget"
    
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: DeparturesTimelineProvider()) { entry in
            DeparturesWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Departures")
        .description("View upcoming TfL departures near your location.")
        .supportedFamilies([.accessoryRectangular, .systemMedium])
    }
}


extension ConfigurationAppIntent {
    fileprivate static var smiley: ConfigurationAppIntent {
        let intent = ConfigurationAppIntent()
        intent.metroStations = true
        intent.railStations = true
        intent.busStations = false
        return intent
    }
}

extension String {
    func deleteSuffix(_ suffix: String) -> String {
        guard self.hasSuffix(suffix) else {
            return self
        }
        return String(self.dropLast(suffix.count))
    }
}

#Preview(as: .systemMedium) {
    DeparturesWidget()
} timeline: {
//    let loc = CLLocation(latitude: 51.5072, longitude: -0.1276)
//    let stnsDeps: [StationDepartures]? = (loc != nil) ? try? await DeparturesFetcher.fetchDepartures(loc: loc, configuration: .smiley) : nil
//    DeparturesEntry(date: .now, configuration: .smiley, locString: "PREVIEW - 51.51, -0.13", stnsDeps: stnsDeps)
    DeparturesEntry(date: .now, configuration: .smiley, locString: "PREVIEW LOC", stnsDeps: getSampleStnsDeps()!)
}
