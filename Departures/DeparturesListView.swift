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
    
    var locationTextView: some View {
        if updateManager.location == nil { Text("\(Image(systemName: "location.slash.fill")) \(updateManager.locationString)") }
        else { Text("\(Image(systemName: "location.fill")) \(updateManager.locationString)") }
    }
    
    var updateButtonView: some View {
        Button {
            Task { await updateManager.updateDepartures(force: true) }
        } label: {
            Label("", systemImage: "arrow.clockwise")
        }.disabled(updateManager.updating)
    }
    
    var body: some View {
        TimelineView(.periodic(from: updateManager.dateDeparturesUpdated ?? Date(), by: 60.0)) { context in
            HStack(spacing: 0) {
                locationTextView
                    .frame(maxWidth: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/, alignment: .leading)
                    .padding([.leading], 15)
                    .lineLimit(1)
                if !updateManager.updating {
                    updateButtonView
                }

                if updateManager.updating {
                    Text("Updating...")
                        .frame(minWidth: 70)
                        .padding([.trailing], 15)
                } else if let updatedMinAgo = updateManager.updatedMinAgo, let updateAttemptedMinAgo = updateManager.updateAttemptedMinAgo {
                    if updatedMinAgo > 2, updateAttemptedMinAgo > 0 {
                        let _ = Task { _ = await updateManager.updateDepartures(force: true) }
                    }
                    Text(updatedMinAgo == 0 ? "Updated now" : "Updated \(updatedMinAgo)min ago")
                        .frame(minWidth: 70)
                        .padding([.trailing], 15)
                }
            }
            .frame(minHeight: 40)
            .background(.opacity(0.05))
            
            if updateManager.stnsDeps.count > 0 {
                List {
                    ForEach(updateManager.stnsDeps) { stnDeps in
                        StationRowView(stnDeps: stnDeps, context: context)
                    }
                }
                .transition(.slide)
                .zIndex(1)
                .animation(.easeInOut(duration: 1.0), value: updateManager.stnsDeps)
                .listStyle(.inset)
                //            .refreshable { _ = await updateManager.updateDepartures() }
            } else if updateManager.updating {
                Text("Loading nearby departures...")
                    .font(.headline)
                    .frame(maxHeight: .infinity)
            } else if updateManager.dateDeparturesUpdated != nil {
                VStack {
                    Text("No departures found.")
                        .font(.headline)
                    Text("Ensure you have enabled the appropriate station types and transport modes in \(Image(systemName: "gear.circle")) Settings.")
                        .font(.caption2)
                }.frame(maxWidth: 300, maxHeight: .infinity)
            } else {
                Text("Error: Please refresh to view updated departures.")
                    .font(.headline)
                    .frame(maxWidth: 300, maxHeight: .infinity)
            }
        }
    }
}

#Preview {
    DeparturesListView()
        .environmentObject(UpdateManager.example())
}
