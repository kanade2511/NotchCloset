//
//  ItemFramePreference.swift
//  NotchCloset
//

import SwiftUI

struct ItemFramePreference: PreferenceKey {
    static var defaultValue: [TrayDrop.DropItem.ID: CGRect] = [:]
    static func reduce(value: inout [TrayDrop.DropItem.ID: CGRect], nextValue: () -> [TrayDrop.DropItem.ID: CGRect]) {
        value.merge(nextValue()) { $1 }
    }
}
