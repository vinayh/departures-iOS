//
//  DeparturesListView.swift
//  Departures
//
//  Created by Vinay Hiremath on 2024-01-13.
//

import SwiftUI

struct DeparturesListView: View {
    @EnvironmentObject var updateManager: UpdateManager
    
    var body: some View {
        NavigationStack {
            HStack {
                Text("Current location: \(updateManager.locationString)")
                    .frame(maxWidth: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/, alignment: .leading)
                    .padding([.leading], 15)
                    .lineLimit(1)
                if updateManager.depsLastUpdated != nil {
                    Text("Updated: \(updateManager.depsLastUpdated!.formatted(date: .omitted, time: .shortened))")
                }
            }
            .font(.system(size: 12))
            List {
                if updateManager.depsLastUpdated != nil {
                    ForEach(updateManager.stnsDeps) { stnDeps in
                        StationRow(stnDeps: stnDeps)
                    }
                    .transition(.slide)
                    .zIndex(1)
                } else {
                    Text("Loading nearby departures...")
                        .transition(.slide)
                        .zIndex(1)
                }
            }
            .refreshable {
                await updateManager.updateDepartures(force: true)
                //            TODO: Handle refresh case when location is not available?
            }
            .navigationTitle("Departures")
        }
    }
}

#Preview {
    DeparturesListView()
        .environmentObject(UpdateManager.example())
}
