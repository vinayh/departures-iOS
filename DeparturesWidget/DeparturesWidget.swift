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

struct Departure: Decodable {
    let id: String
    let line: String
    let mode: String
    let destination: String
    let arrival_time: String
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
    @Published var location: CLLocation? = nil
    @Published var locationString: String = "Unknown"
    
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
            locationString = "Location unavailable"
            return
        }
        locationString = "Lat: \(location.coordinate.latitude), lon: \(location.coordinate.longitude)"
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        location = nil
        locationString = "Error: \(error.localizedDescription)"
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:  // Location services are available.
            locationManager.startUpdatingLocation()
            break
        case .restricted, .denied:  // Location services currently unavailable.
            locationString = "Location access denied"
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
    
    var body: some View {
        VStack {
            //            Text("Time:")
            //            Text(entry.date, style: .time)
            
            Text("Location: \(entry.locString)")
                .font(.system(size: 6))
            
            Text("Station types:")
                .font(.system(size: 6))
            Text(entry.configuration.stationTypes)
                .font(.system(size: 6))
            
            if entry.stnsDeps != nil {
                Text(entry.stnsDeps!.map {
                    $0.station.name
                }.joined(separator: "\n"))
                .font(.system(size: 8))
            }
            else {
                Text("Unable to fetch stations")
                    .font(.system(size: 8))
            }
        }
    }
}

struct DeparturesFetcher {
    enum DepartureFetcherError: Error {
        case departureDataCorrupted
    }
    
    private static var cachePath: URL {
        URL.cachesDirectory.appending(path: "departures")
    }
    
    static var cachedDepartures: [StationDepartures]? {
        guard let data = try? Data(contentsOf: cachePath) else {
            return nil
        }
        let stnsDeps = try? JSONDecoder().decode([StationDepartures].self, from: data)
        return stnsDeps
    }
    
    static var cachedDeparturesAvailable: Bool {
        cachedDepartures != nil
    }
    
    static func fetchDepartures(loc: CLLocation, stationTypes: String) async throws -> [StationDepartures] {
        let url = URL(string: "https://departures-backend.azurewebsites.net/api/nearest?lat=\(loc.coordinate.latitude)&lng=\(loc.coordinate.longitude)")!
        
        // TODO: Include station types in future requests
        //        let url = URL(string: "https://departures-backend.azurewebsites.net/api/nearest?lat=\(loc.coordinate.latitude)&lng=\(loc.coordinate.longitude)&stnTypes=\(stationTypes)")!
        
        // Fetch JSON
        let (data, _) = try await URLSession.shared.data(from: url)
        
        // Parse JSON
        let stnsDeps = try JSONDecoder().decode([StationDepartures].self, from: data)
        
        // Spawn task to cache data
        Task {
            try? await cache(data)
        }
        return stnsDeps
    }
    
    private static func cache(_ departureData: Data) async throws {
        try departureData.write(to: cachePath)
    }
}


struct DeparturesTimelineProvider: AppIntentTimelineProvider {
    typealias Entry = DeparturesEntry
    typealias Intent = ConfigurationAppIntent
    var locationManager = LocationManager()
    
    func placeholder(in context: Context) -> Entry {
        return DeparturesEntry(date: Date(),
                               configuration: ConfigurationAppIntent(),
                               locString: locationManager.locationString,
                               stnsDeps: getSampleStnsDeps()!)
    }
    
    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> DeparturesEntry {
        var snapshotDepartures: ConfigurationAppIntent
        
        if context.isPreview && !DeparturesFetcher.cachedDeparturesAvailable {
            snapshotDepartures = ConfigurationAppIntent() // If not cached
        } else {
            snapshotDepartures = ConfigurationAppIntent() // TODO: Otherwise use cached
        }
        let entry = DeparturesEntry(date: Date(),
                                    configuration: snapshotDepartures,
                                    locString: locationManager.locationString,
                                    stnsDeps: getSampleStnsDeps()!)
        return entry
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<DeparturesEntry> {
        let loc = locationManager.location
        let stnsDeps: [StationDepartures]? = (loc != nil) ? try? await DeparturesFetcher.fetchDepartures(loc: loc!, stationTypes: configuration.stationTypes) : nil
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
        intent.stationTypes = "NaptanMetroStation,NaptanRailStation"
        return intent
    }
}

#Preview(as: .systemSmall) {
    DeparturesWidget()
} timeline: {
    DeparturesEntry(date: .now, configuration: .smiley, locString: "Loc string for preview", stnsDeps: getSampleStnsDeps()!)
}
