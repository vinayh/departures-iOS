//
//  DepRow.swift
//  Departures
//
//  Created by Vinay Hiremath on 2024-01-11.
//

import SwiftUI

struct DepartureRow: View {
    let departure: Departure

    var body: some View {
        HStack {
            let dest = Departure.shortenDestName(departure.destination)
            let line = Departure.formatLineName(departure.line)
            Text("\(dest) - \(line)")
            Spacer()
            Text(String(departure.arrivingInMin()))
        }
    }
}

#Preview {
    DepartureRow(departure: Departure.example())
}
