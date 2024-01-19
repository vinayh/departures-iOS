//
//  DeparturesView.swift
//  Departures
//
//  Created by Vinay Hiremath on 2024-01-11.
//

import SwiftUI

extension PresentationDetent {
    static let bar = Self.fraction(0.10)
    static let small = Self.fraction(0.25)
}

struct DeparturesView: View {
    @State private var settingsDetent = PresentationDetent.small
    @State private var showingSettings = false
    
    var settingsButtonView: some View {
        Button {
            showingSettings.toggle()
        } label: {
            Image(systemName: "gear.circle")
                .font(.system(size: 24))
                .padding(7)
                .background(Color(UIColor.systemBackground).opacity(0.7))
                .clipShape(Circle())
                .shadow(radius: 3)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(EdgeInsets(top: 5, leading: 5, bottom: 0, trailing: 0))
    }
    
    var body: some View {
        let showingList = Binding<Bool>(
            get: { !showingSettings },
            set: { showingSettings = !$0 }
        )
        
        NavigationStack {
            ZStack {
                DeparturesMapView()
                    .sheet(isPresented: showingList) {
                        DeparturesListView()
                            .presentationDetents(
                                [.bar, .small, .medium, .large],
                                selection: $settingsDetent
                            )
                            .presentationBackgroundInteraction(.enabled(upThrough: .medium))
                            .interactiveDismissDisabled()
                    }
                settingsButtonView
            }
            .navigationDestination(isPresented: $showingSettings) {
                SettingsView()
            }
        }
    }
}

#Preview {
    DeparturesView()
        .environmentObject(UpdateManager.example())
}
