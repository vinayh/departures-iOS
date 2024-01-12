//
//  ContentView.swift
//  Departures
//
//  Created by Vinay Hiremath on 2024-01-05.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            DeparturesView()
                .tabItem { Label("Departures", systemImage: "tram.fill") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gear") }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(UpdateManager())
}
