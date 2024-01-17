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
    var updatedMinAgo: Int {
        Int(-updateManager.dateDeparturesUpdated!.timeIntervalSinceNow/60)
    }
    var updateText: String {
        if updateManager.updating {
            return "Updating..."
        } else if updateManager.dateDeparturesUpdated != nil {
            return updatedMinAgo == 0 ? "Updated now" : "Updated \(updatedMinAgo)min ago"
        } else {
            return ""
        }
    }
    
    var body: some View {
        HStack {
            Text("Location: \(updateManager.locationString)")
                .frame(maxWidth: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/, alignment: .leading)
                .padding([.leading], 15)
                .lineLimit(1)
            if updateManager.dateDeparturesUpdated != nil {
                TimelineView(.periodic(from: updateManager.dateDeparturesUpdated!, by: 60.0)) { context in
                    let updatedMinAgo = Int((context.date.timeIntervalSince1970 - updateManager.dateDeparturesUpdated!.timeIntervalSince1970)/60)
                    Text(updatedMinAgo == 0 ? "Updated now" : "Updated \(updatedMinAgo)min ago")
                        .padding([.trailing], 15)
                }
            } else if updateManager.updating {
                Text("Updating...")
            }
            
        }
        .frame(minHeight: 40)
        .background(.opacity(0.05))
        //        if updateManager.numCurrentlyUpdating < 1 {
        //            Button("Refresh") {
        //                await updateManager.updateDeparturesApp(force: true)
        //            }
        //        }
        
        if updateManager.dateDeparturesUpdated != nil {
            List {
                ForEach(updateManager.stnsDeps) { stnDeps in
                    StationRow(stnDeps: stnDeps)
                }
            }
            .transition(.slide)
            .zIndex(1)
            .animation(.easeInOut(duration: 1.0), value: updateManager.stnsDeps)
            .listStyle(.inset)
            .refreshable {
                _ = await updateManager.updateDepartures()
            }
        } else {
            Text("Loading nearby departures...")
                .frame(maxHeight: .infinity)
        }
    }
}

#Preview {
    DeparturesListView()
        .environmentObject(UpdateManager.example())
}
