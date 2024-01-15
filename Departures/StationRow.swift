//
//  StationRow.swift
//  Departures
//
//  Created by Vinay Hiremath on 2024-01-12.
//

import SwiftUI

struct StationRow: View {
    @Environment(\.self) var environment
    let stnDeps: StationDepartures
    
    var body: some View {
        VStack {
            Text(stnDeps.station.nameShort)
                .frame(maxWidth: .infinity, alignment: .leading)
                .font(.title2)
                .bold()
            Grid(verticalSpacing: 2.0) {
                let mergedDepartures = stnDeps.mergedDepartures
                ForEach(mergedDepartures.indices, id: \.self) { idx in
                    let mergedDeps = mergedDepartures[idx]
                    let times: String = mergedDeps.map { dep in "\(dep.arrivingInMin())'" }
                                            .joined(separator: ", ")
                    GridRow {
                        HStack {
                            Text(mergedDeps.first!.destinationShort)
                            Text(mergedDeps.first!.lineFormatted)
                                .font(.caption2)
                                .bold()
                                .padding(2.0)
                                .background(mergedDeps.first!.backgroundColor)
                                .foregroundStyle(mergedDeps.first!.foregroundColor(environment))
                                .cornerRadius(/*@START_MENU_TOKEN@*/3.0/*@END_MENU_TOKEN@*/)
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
        .listRowSeparator(/*@START_MENU_TOKEN@*/.visible/*@END_MENU_TOKEN@*/, edges: [.bottom])
    }
}

#Preview {
    StationRow(stnDeps: UpdateManager.example().stnsDeps[1])
}
