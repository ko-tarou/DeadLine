//
//  Item.swift
//  DeadLine
//
//  Created by kota on 2025/05/15.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
