//
//  DragSourceView.swift
//  NotchCloset
//

import Cocoa
import SwiftUI

struct DragSourceOverlay: NSViewRepresentable {
    let item: TrayDrop.DropItem
    let onDragStarted: () -> Void
    let onDragEnded: () -> Void

    func makeNSView(context: Context) -> DragSourceImpl {
        DragSourceImpl()
    }

    func updateNSView(_ nsView: DragSourceImpl, context: Context) {
        nsView.item = item
        nsView.onDragStarted = onDragStarted
        nsView.onDragEnded = onDragEnded
    }
}

final class DragSourceImpl: NSView, NSDraggingSource {
    var item: TrayDrop.DropItem?
    var onDragStarted: (() -> Void)?
    var onDragEnded: (() -> Void)?

    private var mouseDownPoint: NSPoint = .zero
    private let dragThreshold: CGFloat = 3

    override func mouseDown(with event: NSEvent) {
        mouseDownPoint = convert(event.locationInWindow, from: nil)
    }

    override func mouseDragged(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        let dx = abs(point.x - mouseDownPoint.x)
        let dy = abs(point.y - mouseDownPoint.y)
        guard dx > dragThreshold || dy > dragThreshold else { return }

        guard let item else { return }
        let tvm = TrayDrop.shared
        let selectedIds = tvm.selectedIDs

        let dragItems: [TrayDrop.DropItem]
        if selectedIds.contains(item.id), selectedIds.count > 1 {
            dragItems = tvm.items.filter { selectedIds.contains($0.id) }
        } else {
            dragItems = [item]
        }

        var draggingItems: [NSDraggingItem] = []
        for each in dragItems {
            if let text = each.textContent {
                let pb = NSPasteboardItem()
                pb.setString(text, forType: .string)
                let di = NSDraggingItem(pasteboardWriter: pb)
                di.setDraggingFrame(bounds, contents: each.workspacePreviewImage)
                draggingItems.append(di)
            } else if each.isWebURL {
                let pb = NSPasteboardItem()
                pb.setString(each.sourceURL.absoluteString, forType: .URL)
                pb.setString(each.sourceURL.absoluteString, forType: .string)
                let di = NSDraggingItem(pasteboardWriter: pb)
                di.setDraggingFrame(bounds, contents: each.workspacePreviewImage)
                draggingItems.append(di)
            } else {
                let pb = NSPasteboardItem()
                pb.setString(each.sourceURL.absoluteString, forType: .fileURL)
                let di = NSDraggingItem(pasteboardWriter: pb)
                di.setDraggingFrame(bounds, contents: each.workspacePreviewImage)
                draggingItems.append(di)
            }
        }

        guard !draggingItems.isEmpty else { return }
        onDragStarted?()

        beginDraggingSession(with: draggingItems, event: event, source: self)
    }

    func draggingSession(_ session: NSDraggingSession, sourceOperationMaskFor context: NSDraggingContext) -> NSDragOperation {
        switch context {
        case .outsideApplication: [.copy, .move]
        case .withinApplication:  [.copy, .move, .generic]
        @unknown default:         .copy
        }
    }

    func draggingSession(_ session: NSDraggingSession, endedAt screenPoint: NSPoint, operation: NSDragOperation) {
        onDragEnded?()
    }
}
