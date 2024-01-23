//
//  DeparturesListHelpers.swift
//  Departures
//
//  Created by Vinay Hiremath on 2024-01-22.
//

import SwiftUI

func locationTextView(_ updateManager: UpdateManager) -> some View {
//    ViewThatFits(in: .horizontal) {
//        let locIconName = updateManager.location == nil ? "location.slash.fill" : "location.fill"
//        Text("\(Image(systemName: locIconName)) \(updateManager.locationString)")
//        Image(systemName: locIconName)
//    }
    let locIconName = updateManager.location == nil ? "location.slash.fill" : "location.fill"
    return Text("\(Image(systemName: locIconName)) \(updateManager.locationString)")
}

func stationImageView(_ stnDeps: StationDepartures) -> AnyView {
    if stnDeps.station.stop_type == "NaptanMetroStation" {
        return AnyView(Image("underground_logo")
            .resizable()
            .aspectRatio(contentMode: .fit))
    } else if stnDeps.station.stop_type == "NaptanRailStation" {
        return AnyView(Image("national_rail_logo")
            .resizable()
            .aspectRatio(contentMode: .fit))
    } else {
        return AnyView(EmptyView())
    }
}
