//
//  DeparturesListHelpers.swift
//  Departures
//
//  Created by Vinay Hiremath on 2024-01-22.
//

import SwiftUI

func locationTextView(_ updateManager: UpdateManager) -> some View {
    ViewThatFits(in: .horizontal) {
        let locIconName = updateManager.location == nil ? "location.slash.fill" : "location.fill"
        Text("\(Image(systemName: locIconName)) \(updateManager.locationString)")
        Image(systemName: locIconName)
    }
}
