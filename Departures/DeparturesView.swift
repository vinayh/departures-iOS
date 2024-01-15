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
    @State private var showingList = true
    @State private var settingsDetent = PresentationDetent.small
    
    var body: some View {
        DeparturesMapView()
            .sheet(isPresented: $showingList) {
                DeparturesListView()
                    .presentationDetents(
                        [.bar, .small, .medium, .large],
                        selection: $settingsDetent
                    )
                    .presentationBackgroundInteraction(.enabled(upThrough: .medium))
                    .interactiveDismissDisabled()
            }
            .buttonStyle(.bordered)
    }
}

#Preview {
    DeparturesView()
        .environmentObject(UpdateManager.example())
}
