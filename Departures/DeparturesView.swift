//
//  DeparturesView.swift
//  Departures
//
//  Created by Vinay Hiremath on 2024-01-11.
//

import SwiftUI

struct DeparturesView: View {
    @EnvironmentObject var currentDepartures: CurrentDepartures
    @EnvironmentObject var locationManager: LocationManager
    
    var body: some View {
        NavigationStack {
            if currentDepartures.stnsDeps != nil {
                List {
                    ForEach(currentDepartures.stnsDeps!) { stnDeps in
                        Section(Station.shortenStationName(stnDeps.station.name)) {
                            ForEach(stnDeps.departures) { dep in
                                DepartureRow(departure: dep)
                            }
                        }
                        .headerProminence(.increased)
                    }
                }
                .refreshable {
                    if locationManager.location != nil {
                        try? await currentDepartures.update(loc: locationManager.location!)
                    }
//                    TODO: Handle refresh case when location is not available?
                }
            } else {
                Text("Departures unavailable")
            }
        }
    }
}

#Preview {
    DeparturesView()
        .environmentObject(CurrentDepartures())
        .environmentObject(LocationManager())
}
