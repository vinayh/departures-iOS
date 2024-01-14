//
//  DeparturesListView.swift
//  Departures
//
//  Created by Vinay Hiremath on 2024-01-13.
//

import SwiftUI


struct DeparturesListView: View {
    @EnvironmentObject var updateManager: UpdateManager
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        HStack {
            Text("Location: \(updateManager.locationString)")
                .frame(maxWidth: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/, alignment: .leading)
                .padding([.leading], 15)
                .lineLimit(1)
            if updateManager.depsLastUpdated != nil {
                Text("Updated: \(updateManager.depsLastUpdated!.formatted(date: .omitted, time: .shortened))")
                    .padding([.trailing], 15)
            }
        }
        .padding([.top, .bottom], 5)
        .background(.opacity(0.1))
        .font(.system(size: 14))
        
        List {
            if updateManager.depsLastUpdated != nil {
                ForEach(updateManager.stnsDeps) { stnDeps in
                    StationRow(stnDeps: stnDeps)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(/*@START_MENU_TOKEN@*/.visible/*@END_MENU_TOKEN@*/, edges: [.bottom])
                }
                .transition(.slide)
                .zIndex(1)
            } else {
                Text("Loading nearby departures...")
                    .transition(.slide)
                    .zIndex(1)
            }
        }
        .animation(.easeInOut(duration: 1.0), value: updateManager.stnsDeps)
        .listStyle(.inset)
        .refreshable {
            await updateManager.updateDepartures(force: true)
            //            TODO: Handle refresh case when location is not available?
        }
    }
}

#Preview {
    DeparturesListView()
        .environmentObject(UpdateManager.example())
}
