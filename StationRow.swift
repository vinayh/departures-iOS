//
//  StationRow.swift
//  Departures
//
//  Created by Vinay Hiremath on 2024-01-12.
//

import SwiftUI

struct StationRow: View {
    let stnDeps: StationDepartures
    
    var body: some View {
        VStack{
            Text(Station.shortenStationName(stnDeps.station.name))
                .frame(maxWidth: .infinity, alignment: .leading)
                .bold()
            Grid {
                let mergedDepartures = stnDeps.mergedDepartures
                ForEach(mergedDepartures.indices, id: \.self) { idx in
                    let mergedDeps = mergedDepartures[idx]
                    let dest = Departure.shortenDestName(mergedDeps[0].destination)
                    let line = Departure.formatLineName(mergedDeps[0].line)
                    let times: String = mergedDeps.map { dep in
                        "\(dep.arrivingInMin())'"
                        }
                        .joined(separator: ", ")
                    GridRow {
                        Text(times)
//                        Text("\(dep.arrivingInMin())'")
                        Text("\(dest) - \(line)")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .font(.system(size: 12))
                    .lineLimit(1)
//                    Text(String(mergedDepartures[idx].count))
                }
            }
        }
    }
}

#Preview {
    StationRow(stnDeps: UpdateManager.example().stnsDeps[1])
}
