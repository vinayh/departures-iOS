//
//  StationRowView.swift
//  DeparturesWatch Watch App
//
//  Created by Vinay Hiremath on 2024-01-22.
//

import SwiftUI

struct StationRowView: View {
    @Environment(\.self) var environment
    let stnDeps: StationDepartures
    let context: TimelineViewDefaultContext
    @ScaledMetric(relativeTo: .headline) var imageWidth = 16.0
    
    var body: some View {
        VStack {
            HStack {
                stationImageView(stnDeps)
                    .frame(width: imageWidth)
                
                Text(stnDeps.station.nameShort)
                    .font(.headline)
                    .bold()
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text("\(Image(systemName: "figure.walk")) \(Int(stnDeps.station.distance))m")
                    .opacity(0.5)
                    .font(.footnote)
                    .frame(alignment: .trailing)
            }.frame(maxWidth: .infinity)
            
            Grid(verticalSpacing: 2.0) {
                let mergedDepartures = stnDeps.mergedDepartures
                ForEach(mergedDepartures.indices, id: \.self) { idx in
                    let firstDep: Departure = mergedDepartures[idx].first!
                    let times: String = mergedDepartures[idx].map { dep in "\(dep.arrivingInMin)'" }
                        .joined(separator: ", ")
                    GridRow {
                        HStack {
                            Text(firstDep.destinationShort)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            RoundedRectangle(cornerRadius: 1.5)
                                .fill(firstDep.backgroundColor)
                                .frame(maxHeight: 10)
                                .aspectRatio(0.25, contentMode: .fit)
                        }
                        Text(times)
                            .frame(maxWidth: 50, alignment: .leading)
                    }
                    .font(.caption2)
                    .lineLimit(1)
                }
            }
        }
        .listRowBackground(Color.clear)
        //        .listRowSeparator(.visible, edges: [.bottom])
    }
}

#Preview {
    TimelineView(.periodic(from: Date(), by: 60.0)) { context in
        StationRowView(stnDeps: UpdateManager.example().stnsDeps[1], context: context)
    }
}
