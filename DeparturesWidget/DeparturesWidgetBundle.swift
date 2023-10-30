//
//  DeparturesWidgetBundle.swift
//  DeparturesWidget
//
//  Created by Vinay Hiremath on 2023-10-30.
//

import WidgetKit
import SwiftUI

@main
struct DeparturesWidgetBundle: WidgetBundle {
    var body: some Widget {
        DeparturesWidget()
        DeparturesWidgetLiveActivity()
    }
}
