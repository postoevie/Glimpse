//
//  Item.swift
//  Glimpse
//
//  Created by Igor Postoev on 3. 7. 2026..
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
