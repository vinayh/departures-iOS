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
    
    var updateButtonView: AnyView {
        switch updateManager.status {
        case .initFetching, .loadedFetching, .noResultsFetching:
            return AnyView(EmptyView())
        default:
            return AnyView(Button {
                Task { await updateManager.updateDepartures(force: true) }
            } label: {
                Label("", systemImage: "arrow.clockwise")
            }.disabled(updateManager.updating))
        }
    }
    
    var updateTextView: AnyView {
        var text: String
        switch updateManager.status {
        case .initFetching, .loadedFetching, .noResultsFetching:
            text = "Updating..."
        case .loaded(let updatedMinAgo, let attemptedMinAgo), .noResults(let updatedMinAgo, let attemptedMinAgo):
            if updatedMinAgo > 2, attemptedMinAgo > 0 {
                let _ = Task { _ = await updateManager.updateDepartures(force: true) }
            }
            text = updatedMinAgo == 0 ? "Updated now" : "Updated \(updatedMinAgo)min ago"
        case .error:
            text = "Error"
        case .initial:
            text = ""
        }
        return AnyView(Text(text)
            .frame(minWidth: 70)
            .padding([.trailing], 15))
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
            .listStyle(.inset)
        )
    }
    
    var body: some View {
        TimelineView(.periodic(from: updateManager.dateDeparturesUpdated ?? Date(), by: 60.0)) { context in
            HStack(spacing: 0) {
                locationTextView(updateManager)
                    .frame(maxWidth: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/, alignment: .leading)
                    .padding([.leading], 15)
                    .lineLimit(1)
                
                updateButtonView
                updateTextView
            }
            .frame(minHeight: 40)
            .background(.opacity(0.05))
            
            switch updateManager.status {
            case .loaded, .loadedFetching:
                listView(context)
            case .initFetching, .noResultsFetching:
                Text("Loading nearby departures...")
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
    }
}

#Preview {
    DeparturesListView()
        .environmentObject(UpdateManager.example())
}
