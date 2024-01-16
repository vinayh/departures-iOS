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
    var updateText: String {
        if updateManager.numCurrentlyUpdating > 0 {
            return "Updating..."
        } else if updateManager.lastDepUpdateFinished != nil {
            return "Updated \(Int(-updateManager.lastDepUpdateFinished!.timeIntervalSinceNow/60))min ago"
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
            Text(updateText)
                .padding([.trailing], 15)
        }
        .frame(minHeight: 40)
        .background(.opacity(0.05))
        if updateManager.numCurrentlyUpdating < 1 {
            Button("Refresh") {
                updateManager.updateDepartures(force: true)
            }
        }
        if updateManager.lastDepUpdateFinished != nil {
            List {
                ForEach(updateManager.stnsDeps) { stnDeps in
                    StationRow(stnDeps: stnDeps)
                }
            }
            .transition(.slide)
            .zIndex(1)
            .animation(.easeInOut(duration: 1.0), value: updateManager.stnsDeps)
            .listStyle(.inset)
//            .refreshable {  }
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
