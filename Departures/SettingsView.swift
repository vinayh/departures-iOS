//
//  SettingsView.swift
//  Departures
//
//  Created by Vinay Hiremath on 2024-01-11.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    @AppStorage("type.NaptanMetroStation") private var metroStations = true
    @AppStorage("type.NaptanRailStation") private var railStations = true
    @AppStorage("type.NaptanPublicBusCoachTram") private var busStops = false
    
    @AppStorage("mode.tube") private var modeTube = true
    @AppStorage("mode.dlr") private var modeDlr = true
    @AppStorage("mode.overground") private var modeOverground = true
    @AppStorage("mode.elizabeth-line") private var modeElizabeth = true
    @AppStorage("mode.bus") private var modeBus = false
    @AppStorage("mode.tram") private var modeTram = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Choose stop types to be displayed") {
                    Toggle("Overground and Elizabeth line", isOn: $railStations)
                    Toggle("Underground and DLR", isOn: $metroStations)
//                    Toggle("Bus and tram", isOn: $busStops)
                }
                
                Section("Choose transport modes to be displayed") {
                    Toggle("DLR", isOn: $modeDlr)
                    Toggle("Elizabeth line", isOn: $modeElizabeth)
                    Toggle("Overground", isOn: $modeOverground)
                    Toggle("Underground", isOn: $modeTube)
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsView()
}
