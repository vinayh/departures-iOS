//
//  DeparturesWatchApp.swift
//  DeparturesWatch Watch App
//
//  Created by Vinay Hiremath on 2024-01-22.
//

import SwiftUI

@main
struct DeparturesWatchApp: App {
    @StateObject var updateManager = UpdateManager()
    
    var body: some Scene {
        WindowGroup {
            DeparturesListView()
                .environmentObject(updateManager)
        }
    }
}
