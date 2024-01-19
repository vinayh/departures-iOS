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
                .padding(5)
                .background(Color(.white))
                .clipShape(Circle())
                .shadow(radius: 3)
                .opacity(0.9)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding([.leading, .top], 10)
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
