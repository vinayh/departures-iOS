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
        VStack{
            Text(stnDeps.station.nameShort)
                .frame(maxWidth: .infinity, alignment: .leading)
                .font(.title2)
                .bold()
            Grid(verticalSpacing: 2.0) {
                let mergedDepartures = stnDeps.mergedDepartures
                ForEach(mergedDepartures.indices, id: \.self) { idx in
                    let mergedDeps = mergedDepartures[idx]
                    let dest = Departure.shortenDestName(mergedDeps.first!.destination)
                    let line = Departure.formatLineName(mergedDeps.first!.line)
                    let times: String = mergedDeps.map { dep in "\(dep.arrivingInMin())'" }
                                            .joined(separator: ", ")
                    GridRow {
                        HStack {
                            Text(dest)
                            Text(line)
                                .font(.caption2)
                                .bold()
                                .padding(2.0)
                                .background(mergedDeps.first!.backgroundColor)
                                .foregroundStyle(mergedDeps.first!.foregroundColor(environment))
                                .cornerRadius(/*@START_MENU_TOKEN@*/3.0/*@END_MENU_TOKEN@*/)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
//                        .animation(.easeInOut(duration: 1.0), value: mergedDeps)
                        
                        Text(times)
                            .frame(maxWidth: 120, alignment: .trailing)
//                            .animation(.easeInOut(duration: 1.0), value: times)
                    }
                    .lineLimit(1)
                }
            }
        }
    }
}

#Preview {
    StationRow(stnDeps: UpdateManager.example().stnsDeps[1])
}
