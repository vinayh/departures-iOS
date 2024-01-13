//
//  DeparturesView.swift
//  Departures
//
//  Created by Vinay Hiremath on 2024-01-11.
//

import SwiftUI

struct DeparturesView: View {
    
    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                DeparturesListView()
                    .environmentObject(UpdateManager())
                    .frame(height: geo.size.height/2)
                DeparturesMapView()
                    .frame(height: geo.size.height/2)
            }
            
        }
    }
}

#Preview {
    DeparturesView()
}
