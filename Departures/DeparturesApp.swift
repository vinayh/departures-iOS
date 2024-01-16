//
//  DeparturesApp.swift
//  Departures
//
//  Created by Vinay Hiremath on 2024-01-05.
//

import SwiftUI

class AppDelegate: NSObject, UIApplicationDelegate {
    private var completion: (() -> Void)? = nil
    
    func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String,
                     completionHandler: @escaping () -> Void) {
        if identifier == "com.vinayh.Departures" {
            completion = completionHandler
        }
    }
    
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        Task { @MainActor in
            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate,
                  let completion = appDelegate.completion else {
                return
            }
            completion()
            print("urlSessionDidFinishEvents in AppDelegate")
        }
    }
}

@main
struct DeparturesApp: App {
    @StateObject var updateManager = UpdateManager(identifier: "com.vinayh.Departures")
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        updateManager.startUpdatingDepartures()
        
        return WindowGroup {
            DeparturesView()
                .environmentObject(updateManager)
        }
    }
}
