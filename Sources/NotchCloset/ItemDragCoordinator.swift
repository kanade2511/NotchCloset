//
//  ItemDragCoordinator.swift
//  NotchCloset
//
//  Created by @kanade2511
//

import AppKit
import Combine

/// Tracks drag state across the tray and provides drag-end detection for move semantics.
class ItemDragCoordinator: ObservableObject {
    static let shared = ItemDragCoordinator()

    @Published var isDragging = false
    @Published var draggedItemId: TrayDrop.DropItem.ID?

    func dragStarted(itemId: TrayDrop.DropItem.ID) {
        draggedItemId = itemId
        isDragging = true
    }

    func dragCompleted(itemId: TrayDrop.DropItem.ID) {
        guard draggedItemId == itemId else { return }
        draggedItemId = nil
        isDragging = false
    }

    func dragCancelled() {
        draggedItemId = nil
        isDragging = false
    }
}
