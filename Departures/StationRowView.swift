//
//  StationRow.swift
//  Departures
//
//  Created by Vinay Hiremath on 2024-01-12.
//

import SwiftUI

struct StationRowView: View {
    @Environment(\.self) var environment
    let stnDeps: StationDepartures
    let context: TimelineViewDefaultContext
    
    var body: some View {
        VStack {
            Text(stnDeps.station.nameShort)
                .frame(maxWidth: .infinity, alignment: .leading)
                .font(.title2)
                .bold()
            Grid(verticalSpacing: 2.0) {
                let mergedDepartures = stnDeps.mergedDepartures
                ForEach(mergedDepartures.indices, id: \.self) { idx in
                    let firstDep: Departure = mergedDepartures[idx].first!
                    let times: String = mergedDepartures[idx].map { dep in "\(dep.arrivingInMin)'" }
                                            .joined(separator: ", ")
                    GridRow {
                        HStack {
                            Text(firstDep.destinationShort)
                            Text(firstDep.lineFormatted)
                                .font(.caption2)
                                .bold()
                                .padding([.top, .bottom], 2.0)
                                .padding([.trailing, .leading], 4.0)
                                .background(firstDep.backgroundColor)
                                .foregroundStyle(firstDep.foregroundColor(environment))
                                .cornerRadius(3.0)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Text(times)
                            .frame(maxWidth: 120, alignment: .trailing)
                    }
                    .lineLimit(1)
                }
            }
        }
        .listRowBackground(Color.clear)
        .listRowSeparator(.visible, edges: [.bottom])
    }
}

#Preview {
    TimelineView(.periodic(from: Date(), by: 60.0)) { context in
        StationRowView(stnDeps: UpdateManager.example().stnsDeps[1], context: context)
    }
}
