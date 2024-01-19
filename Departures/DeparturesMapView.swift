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
    @State var position: MapCameraPosition = .userLocation(followsHeading: true, fallback: .automatic)

    var body: some View {
        Map(position: $position) {
            UserAnnotation()
            ForEach(updateManager.stnsDeps) { stnDeps in
                Marker(stnDeps.station.nameShort, systemImage: "tram.fill", coordinate: CLLocationCoordinate2D(latitude: CLLocationDegrees(stnDeps.station.lat), longitude: CLLocationDegrees(stnDeps.station.lon)))
            }
        }
        .mapControls {
            MapUserLocationButton()
        }
        .onChange(of: position) {
            if position.followsUserLocation {
                withAnimation {
                    position = .automatic
                }
            }
        }
        .onChange(of: updateManager.stnsDeps.map {stnsDep in stnsDep.station.id} ) {
            if position.followsUserLocation {
                withAnimation {
                    position = .automatic
                }
            }
        }
    }
}

#Preview {
    DeparturesMapView()
        .environmentObject(UpdateManager.example())
}
