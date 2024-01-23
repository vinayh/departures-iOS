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
    @ScaledMetric(relativeTo: .title2) var imageWidth = 18.0
    
    
    
    var body: some View {
        HStack {
            stationImageView(stnDeps)
                .frame(width: imageWidth)
            
            Text(stnDeps.station.nameShort)
                .font(.title2)
                .bold()
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Text("\(Image(systemName: "figure.walk")) \(Int(stnDeps.station.distance))m")
                .opacity(0.5)
                .font(.footnote)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }.listRowSeparator(.hidden)
        
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
                    }.frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text(times)
                        .frame(maxWidth: 100, alignment: .leading)
                }
                .lineLimit(1)
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
