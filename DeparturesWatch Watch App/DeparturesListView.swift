//
//  DeparturesListView.swift
//  DeparturesWatch Watch App
//
//  Created by Vinay Hiremath on 2024-01-22.
//

import SwiftUI

struct DeparturesListView: View {
    @EnvironmentObject var updateManager: UpdateManager
    @Environment(\.dismiss) var dismiss
    @State private var showingSettings = false
    
    var settingsButtonView: some View {
        Button {
            showingSettings.toggle()
        } label: {
            Image(systemName: "gear.circle")
                .font(.system(size: 16))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }
    
    var updateButtonView: some View {
        Button {
            Task { await updateManager.updateDepartures(force: true) }
        } label: {
            Label("", systemImage: "arrow.clockwise")
                .font(.footnote)
        }.disabled(updateManager.updating)
            .buttonStyle(.plain)
    }
    
    var updateTextView: some View {
        var text: String
        switch updateManager.status {
        case .initFetching, .loadedFetching, .noResultsFetching:
            text = "..."
        case .loaded(let updatedMinAgo, let attemptedMinAgo), .noResults(let updatedMinAgo, let attemptedMinAgo):
            if updatedMinAgo > 2, attemptedMinAgo > 0 {
                let _ = Task { _ = await updateManager.updateDepartures(force: true) }
            }
            text = "\(updatedMinAgo)' ago"
        case .error:
            text = "Error"
        case .initial:
            text = ""
        }
        return Text(text)
    }
    
    func messageView(title: String, subtitle: String) -> AnyView {
        AnyView(VStack {
            Text(title)
                .font(.headline)
            Text(subtitle)
                .font(.caption2)
        }.frame(maxWidth: 300, maxHeight: .infinity))
    }
    
    func listView(_ context: TimelineViewDefaultContext) -> AnyView {
        AnyView(List {
            ForEach(updateManager.stnsDeps) { stnDeps in
                StationRowView(stnDeps: stnDeps, context: context)
            }
        }
            .transition(.slide)
            .zIndex(1)
            .animation(.easeInOut(duration: 1.0), value: updateManager.stnsDeps)
        )
    }
    
    var body: some View {
        NavigationStack {
            TimelineView(.periodic(from: updateManager.dateDeparturesUpdated ?? Date(), by: 60.0)) { context in
                HStack {
                    updateButtonView
                    updateTextView
                        .frame(alignment: .leading)
                    locationTextView(updateManager)
                        .frame(maxWidth: .infinity)
                    settingsButtonView
                        .frame(alignment: .trailing)
                }
                .lineLimit(1)
                .frame(maxWidth: .infinity)
                .font(.footnote)
                .padding(0)
                
                switch updateManager.status {
                case .loaded, .loadedFetching:
                    listView(context)
                case .initFetching, .noResultsFetching:
                    Text("Loading departures...")
                        .font(.headline)
                        .frame(maxHeight: .infinity)
                case .noResults:
                    messageView(title: "No departures found.", subtitle: "Ensure you have enabled the appropriate station types and transport modes in Settings.")
                case .initial:
                    messageView(title: "Welcome!", subtitle: "Tap the refresh button above to view your nearest departures.")
                case .error:
                    messageView(title: "Error!", subtitle: "Please refresh by tapping the button above to view updated departures.")
                }
            }
            .navigationDestination(isPresented: $showingSettings) {
                SettingsView()
            }
        }
    }
}

#Preview {
    DeparturesListView()
        .environmentObject(UpdateManager.example())
}
