//
//  Item.swift
//  TOTPApp
//
//  Created by Lilly Cham on 20/06/2023.
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
