//
//  Item.swift
//  ChromeProfile
//
//  Created by Karmjit Singh on 21/2/2026.
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
