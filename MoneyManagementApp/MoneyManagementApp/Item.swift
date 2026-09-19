//
//  Item.swift
//  MoneyManagementApp
//
//  Created by Engineer MacBook Air on 2026/09/06.
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
