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
    
//    private var rotateAnimation: IndefiniteSymbolEffect {
//        Animation.linear(duration: 2.0).repeatForever(autoreverses: false)
//    }
//    
    var locationTextView: some View {
        if updateManager.location == nil { Text("\(Image(systemName: "location.slash.fill")) \(updateManager.locationString)") }
        else { Text("\(Image(systemName: "location.fill")) \(updateManager.locationString)") }
    }
    
    var updateTextView: some View {
        if updateManager.updating {
            AnyView(Text("Updating..."))
        } else if updateManager.dateDeparturesUpdated != nil {
            AnyView(TimelineView(.periodic(from: updateManager.dateDeparturesUpdated!, by: 60.0)) { context in
                let updatedMinAgo = Int((context.date.timeIntervalSince1970 - updateManager.dateDeparturesUpdated!.timeIntervalSince1970)/60)
                Text(updatedMinAgo == 0 ? "Updated now" : "Updated \(updatedMinAgo)min ago")
            })
        } else { AnyView(Text("")) }
    }
    
    var body: some View {
        HStack(spacing: 0) {
            locationTextView
                .frame(maxWidth: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/, alignment: .leading)
                .padding([.leading], 15)
                .lineLimit(1)
            if !updateManager.updating {
                Button {
                    Task { await updateManager.updateDepartures() }
                } label: {
                    Label("", systemImage: "arrow.clockwise")
                }.disabled(updateManager.updating)
//                .symbolEffect(.pulse, isActive: updateManager.updating)
            }
            updateTextView
                .frame(minWidth: 70)
                .padding([.trailing], 15)
        }
        .frame(minHeight: 40)
        .background(.opacity(0.05))
        
        if updateManager.stnsDeps.count > 0 {
            List {
                ForEach(updateManager.stnsDeps) { stnDeps in
                    StationRow(stnDeps: stnDeps)
                }
            }
            .transition(.slide)
            .zIndex(1)
            .animation(.easeInOut(duration: 1.0), value: updateManager.stnsDeps)
            .listStyle(.inset)
//            .refreshable { _ = await updateManager.updateDepartures() }
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
