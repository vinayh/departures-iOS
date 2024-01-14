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
    @State var mapRect = MKMapRect()
    
    @State var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 51.507222, longitude: -0.1275),
        span: MKCoordinateSpan(latitudeDelta: 1, longitudeDelta: 1)
        )
    private let initPosition = MapCameraPosition.region(MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 51.507222, longitude: -0.1275),
        span: MKCoordinateSpan(latitudeDelta: 1, longitudeDelta: 1)
        )
    )
    
    func MKMapRectForCoordinateRegion(region:MKCoordinateRegion) -> Binding<MKMapRect> {
        let topLeft = CLLocationCoordinate2D(latitude: region.center.latitude + (region.span.latitudeDelta/2), longitude: region.center.longitude - (region.span.longitudeDelta/2))
        let bottomRight = CLLocationCoordinate2D(latitude: region.center.latitude - (region.span.latitudeDelta/2), longitude: region.center.longitude + (region.span.longitudeDelta/2))

        let a = MKMapPoint(topLeft)
        let b = MKMapPoint(bottomRight)
        
        @State var rect = MKMapRect(origin: MKMapPoint(x:min(a.x,b.x), y:min(a.y,b.y)), size: MKMapSize(width: abs(a.x-b.x), height: abs(a.y-b.y)))
        return $rect
    }
    
    @State var position: MapCameraPosition = .userLocation(followsHeading: true, fallback: .automatic)
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
        
        Map(mapRect: MKMapRectForCoordinateRegion(region: region), annotationItems: updateManager.stnsDeps) { stnDeps in
//            UserAnnotation()
            MapMarker(coordinate: CLLocationCoordinate2D(latitude: CLLocationDegrees(stnDeps.station.lat), longitude: CLLocationDegrees(stnDeps.station.lon)))
//            ForEach(updateManager.stnsDeps) { stnDeps in
//                Marker(stnDeps.station.name, coordinate: CLLocationCoordinate2D(latitude: stnDeps.station.lat, longitude: stnDeps.station.lon))
//            }
        }
    }
}

#Preview {
    DeparturesMapView()
}
