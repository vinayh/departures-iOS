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
    
//    private let initPosition = MapCameraPosition.region(MKCoordinateRegion(
//        center: CLLocationCoordinate2D(latitude: 51.507222, longitude: -0.1275),
//        span: MKCoordinateSpan(latitudeDelta: 1, longitudeDelta: 1)
//        )
//    )
    
    @State var position: MapCameraPosition = .userLocation(followsHeading: true, fallback: .automatic)
    
    var body: some View {
//        @State var userPosition = MapCameraPosition.region(MKCoordinateRegion(
//            center: CLLocationCoordinate2D(latitude: updateManager.location?.coordinate.latitude ?? 51.507222, longitude: updateManager.location?.coordinate.longitude ?? -0.1275),
//            span: MKCoordinateSpan(latitudeDelta: 1, longitudeDelta: 1)
//        ))
        
        Map(position: $position) {
            UserAnnotation()
            ForEach(updateManager.stnsDeps) { stnDeps in
                Marker(stnDeps.station.nameShort, coordinate: CLLocationCoordinate2D(latitude: CLLocationDegrees(stnDeps.station.lat), longitude: CLLocationDegrees(stnDeps.station.lon)))
            }
        }
        .mapControls {
            MapUserLocationButton()
        }
        .onChange(of: position) {
            if position.followsUserLocation {
                position = .automatic
            }
        }
        .onChange(of: updateManager.stnsDeps.map {stnsDep in stnsDep.station.id} ) {
            if position.followsUserLocation {
                position = .automatic
            }
        }
    }
}

#Preview {
    DeparturesMapView()
        .environmentObject(UpdateManager.example())
}
