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
    let jsonSampleString = """
    [{"station": {"lat": 51.499544, "lon": -0.133608, "id": "940GZZLUSJP", "name": "St. James's Park Underground Station"}, "departures": [{"id": "89841613", "line": "district", "mode": "tube", "destination": "Barking Underground Station", "arrival_time": "2024-01-07T13:49:51+00:00"}, {"id": "-1468902663", "line": "circle", "mode": "tube", "destination": "Hammersmith (H&C Line) Underground Station", "arrival_time": "2024-01-07T13:51:23+00:00"}, {"id": "-609008992", "line": "district", "mode": "tube", "destination": "Upminster Underground Station", "arrival_time": "2024-01-07T13:52:39+00:00"}, {"id": "-1206602181", "line": "district", "mode": "tube", "destination": "Richmond Underground Station", "arrival_time": "2024-01-07T13:53:09+00:00"}, {"id": "-1069155320", "line": "circle", "mode": "tube", "destination": "Edgware Road (Circle Line) Underground Station", "arrival_time": "2024-01-07T13:54:23+00:00"}]}, {"station": {"lat": 51.50132, "lon": -0.124861, "id": "940GZZLUWSM", "name": "Westminster Underground Station"}, "departures": [{"id": "546070801", "line": "jubilee", "mode": "tube", "destination": "Stratford Underground Station", "arrival_time": "2024-01-07T13:49:53+00:00"}, {"id": "-832832012", "line": "jubilee", "mode": "tube", "destination": "Stanmore Underground Station", "arrival_time": "2024-01-07T13:50:40+00:00"}, {"id": "-1646054147", "line": "jubilee", "mode": "tube", "destination": "Stratford Underground Station", "arrival_time": "2024-01-07T13:51:10+00:00"}, {"id": "757566638", "line": "district", "mode": "tube", "destination": "Richmond Underground Station", "arrival_time": "2024-01-07T13:51:39+00:00"}, {"id": "-1872108200", "line": "district", "mode": "tube", "destination": "Barking Underground Station", "arrival_time": "2024-01-07T13:52:08+00:00"}]}, {"station": {"lat": 51.50741, "lon": -0.127277, "id": "940GZZLUCHX", "name": "Charing Cross Underground Station"}, "departures": [{"id": "295018936", "line": "bakerloo", "mode": "tube", "destination": "Stonebridge Park Underground Station", "arrival_time": "2024-01-07T13:49:46+00:00"}, {"id": "-923680746", "line": "northern", "mode": "tube", "destination": "Kennington Underground Station", "arrival_time": "2024-01-07T13:50:09+00:00"}, {"id": "-813941547", "line": "bakerloo", "mode": "tube", "destination": "Elephant & Castle Underground Station", "arrival_time": "2024-01-07T13:52:22+00:00"}, {"id": "-923680747", "line": "northern", "mode": "tube", "destination": "Kennington Underground Station", "arrival_time": "2024-01-07T13:53:09+00:00"}, {"id": "1780910958", "line": "bakerloo", "mode": "tube", "destination": "Queen's Park Underground Station", "arrival_time": "2024-01-07T13:53:52+00:00"}]}, {"station": {"lat": 51.507058, "lon": -0.122666, "id": "940GZZLUEMB", "name": "Embankment Underground Station"}, "departures": [{"id": "-658783477", "line": "bakerloo", "mode": "tube", "destination": "Elephant & Castle Underground Station", "arrival_time": "2024-01-07T13:49:46+00:00"}, {"id": "-1931687186", "line": "northern", "mode": "tube", "destination": "Battersea Power Station Underground Station", "arrival_time": "2024-01-07T13:49:52+00:00"}, {"id": "676825927", "line": "district", "mode": "tube", "destination": "Richmond Underground Station", "arrival_time": "2024-01-07T13:50:09+00:00"}, {"id": "1407900139", "line": "district", "mode": "tube", "destination": "Upminster Underground Station", "arrival_time": "2024-01-07T13:50:39+00:00"}, {"id": "1652250114", "line": "northern", "mode": "tube", "destination": "Kennington Underground Station", "arrival_time": "2024-01-07T13:51:38+00:00"}]}, {"station": {"lat": 51.496359, "lon": -0.143102, "id": "940GZZLUVIC", "name": "Victoria Underground Station"}, "departures": [{"id": "1775592397", "line": "victoria", "mode": "tube", "destination": "Walthamstow Central Underground Station", "arrival_time": "2024-01-07T13:49:49+00:00"}, {"id": "-1748174221", "line": "circle", "mode": "tube", "destination": "Hammersmith (H&C Line) Underground Station", "arrival_time": "2024-01-07T13:49:53+00:00"}, {"id": "-468850134", "line": "district", "mode": "tube", "destination": "Upminster Underground Station", "arrival_time": "2024-01-07T13:51:08+00:00"}, {"id": "-725928415", "line": "victoria", "mode": "tube", "destination": "Brixton Underground Station", "arrival_time": "2024-01-07T13:51:09+00:00"}, {"id": "-725993951", "line": "victoria", "mode": "tube", "destination": "Walthamstow Central Underground Station", "arrival_time": "2024-01-07T13:52:39+00:00"}]}]
    """
    let jsonData = Data(jsonSampleString.utf8)
    let stnsDeps = try? JSONDecoder().decode([StationDepartures].self, from: jsonData)
    return stnsDeps
}

func shortenStationName(_ station: String) -> String {
    return station
        .replacingOccurrences(of: "Underground Station", with: "🚇")
        .replacingOccurrences(of: "Rail Station", with: "🚆")
        .replacingOccurrences(of: "DLR Station", with: "🚈")
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

struct Departure: Decodable {
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

struct Station: Decodable {
    let id: String
    let lat: Float
    let lon: Float
    let name: String
}

struct StationDepartures: Decodable {
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
        locationString = String(format: "Lat: %.2f, lon: %.2f", location.coordinate.latitude, location.coordinate.longitude)
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
    
    private static func renderStnDeps(_ stnDeps: StationDepartures) -> AnyView {
        return AnyView(VStack {
            Text(shortenStationName(stnDeps.station.name))
                .frame(maxWidth: .infinity, alignment: .leading)
                .font(.system(size: 8))
                .lineLimit(1)
            Grid() {
                ForEach(stnDeps.departures[...2].indices, id: \.self) { index in
                    let dep = stnDeps.departures[index]
                    GridRow {
                        Text("\(dep.arrivingInMin())'")
                            .bold()
                        Text("\(shortenDestName(dep.destination)) - \(formatLineName(dep.line))")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .underline(color: Color(dep.line))
                    }
                    .font(.system(size: 6))
                    .lineLimit(1)
                }
            }
        })
    }
    
    var body: some View {
        let stopTypes: String = (entry.configuration.metroStations ? "🚇" : "")
            + (entry.configuration.railStations ? "🚆" : "")
            + (entry.configuration.busStations ? "🚌" : "")
        // TODO: Improve text adaptation to widget type/size, currently works passably for small and medium widgets
        VStack {
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
                
                LazyVGrid(columns: columns) {
                    ForEach(entry.stnsDeps!.indices, id: \.self) { index in
                        VStack {
                            DeparturesWidgetEntryView.renderStnDeps(entry.stnsDeps![index])
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

#Preview(as: .systemSmall) {
    DeparturesWidget()
} timeline: {
    DeparturesEntry(date: .now, configuration: .smiley, locString: "PREVIEW LOC", stnsDeps: getSampleStnsDeps()!)
}
