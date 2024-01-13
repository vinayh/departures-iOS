//
//  DeparturesApp.swift
//  Departures
//
//  Created by Vinay Hiremath on 2024-01-05.
//

import SwiftUI

@main
struct DeparturesApp: App {
    @StateObject var updateManager = UpdateManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(updateManager)
        }
    }
}

