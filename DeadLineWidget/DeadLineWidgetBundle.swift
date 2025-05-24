//
//  DeadLineWidgetBundle.swift
//  DeadLineWidget
//
//  Created by kota on 2025/05/22.
//

import WidgetKit
import SwiftUI

@main
struct DeadLineWidgetBundle: WidgetBundle {
    var body: some Widget {
        DeadLineWidget()
        DeadLineWidgetControl()
        DeadLineWidgetLiveActivity()
    }
}
