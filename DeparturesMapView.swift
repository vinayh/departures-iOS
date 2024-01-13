//
//  DeparturesMapView.swift
//  Departures
//
//  Created by Vinay Hiremath on 2024-01-13.
//

import SwiftUI
import MapKit

struct DeparturesMapView: View {
    @EnvironmentObject var updateManager: UpdateManager
    private let initPosition = MapCameraPosition.region(MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 51.507222, longitude: -0.1275),
        span: MKCoordinateSpan(latitudeDelta: 1, longitudeDelta: 1)
        )
    )
    //                                                                updateManager.location?.coordinate
    
    var body: some View {
//        @State var region = MKCoordinateRegion(
//            center: CLLocationCoordinate2D(latitude: 51.507222, longitude: -0.1275),
//            span: MKCoordinateSpan(latitudeDelta: 1, longitudeDelta: 1)
//        )
        
//        @State var position = MapCameraPosition.region(MKCoordinateRegion(
//            center: CLLocationCoordinate2D(latitude: 51.507222, longitude: -0.1275),
//            span: MKCoordinateSpan(latitudeDelta: 1, longitudeDelta: 1)
//            )
//        )
        
        @State var position: MapCameraPosition = .userLocation(followsHeading: true, fallback: .automatic)
        
//        var stnDeps = updateManager.stnsDeps[0]
        Map(position: $position) {
            UserAnnotation()
//            Marker(stnDeps.station.name, coordinate: CLLocationCoordinate2D(latitude: stnDeps.station.lat, longitude: stnDeps.station.lon))
//            ForEach(updateManager.stnsDeps) { stnDeps in
//                Marker(stnDeps.station.name, coordinate: CLLocationCoordinate2D(latitude: stnDeps.station.lat, longitude: stnDeps.station.lon))
//            }
        }
    }
}

#Preview {
    DeparturesMapView()
}
