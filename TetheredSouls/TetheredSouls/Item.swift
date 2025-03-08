//
//  Item.swift
//  TetheredSouls
//
//  Created by Jahan khan on 11/3/24.
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
