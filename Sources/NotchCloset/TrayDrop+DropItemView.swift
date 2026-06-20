//
//  TrayDrop+DropItemView.swift
//  NotchCloset
//
//  Created by 秋星桥 on 2024/7/8.
//  Modified by @kanade2511
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers
import Cocoa

struct DropItemView: View {
    let item: TrayDrop.DropItem
    let index: Int
    let total: Int
    let isInitialBatch: Bool
    let cascadeCount: Int
    @StateObject var vm: NotchViewModel
    @StateObject var tvm = TrayDrop.shared
    @ObservedObject var dragCoordinator = ItemDragCoordinator.shared

    @State var hover = false
    @State var dropTargeted = false
    @State private var dragImage: NSImage?

    private var visible: Bool {
        !isInitialBatch || index < cascadeCount
    }

    var body: some View {
        VStack {
            Image(nsImage: item.workspacePreviewImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: 32, maxHeight: 32)
            Text(item.fileName)
                .multilineTextAlignment(.center)
                .font(.system(.footnote, design: .rounded))
                .frame(maxWidth: 56)
                .lineLimit(2)
                .frame(minHeight: 28, alignment: .top)
        }
        .frame(width: 60, height: 78)
        .background {
            if tvm.selectedIDs.contains(item.id) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.blue.opacity(0.18))
            }
        }
        .contentShape(Rectangle())
        .opacity(visible ? 1 : 0)
        .offset(y: visible ? 0 : -16)
        .animation(vm.animationInsert, value: visible)
        .transition(.asymmetric(
            insertion: .identity,
            removal: .opacity
                .animation(vm.animationRemove.delay(Double(total - 1 - index) * 0.04))
        ))
        .onHover { hover = $0 }
        .animation(vm.animationHover, value: hover)
        .animation(vm.animationHover, value: dropTargeted)
        .overlay {
            DragSourceOverlay(
                item: item,
                onDragStarted: { dragCoordinator.dragStarted(itemId: item.id) },
                onDragEnded: { dragCoordinator.dragCompleted(itemId: item.id) }
            )
        }
        .onDrop(of: [.data, .directory, .folder, .url, .text, .plainText, .utf8PlainText], isTargeted: $dropTargeted) { providers in
            guard let draggedId = dragCoordinator.draggedItemId,
                  draggedId != item.id
            else {
                return false
            }

            if tvm.selectedIDs.contains(draggedId), tvm.selectedIDs.count > 1 {
                let selectedIds = tvm.selectedIDs
                guard !selectedIds.contains(item.id) else { return false }

                let selectedWithIdx: [(Int, TrayDrop.DropItem)] = tvm.items.enumerated()
                    .filter { selectedIds.contains($0.element.id) }
                    .map { ($0.offset, $0.element) }

                var inEdit = tvm.items
                for (idx, _) in selectedWithIdx.reversed() {
                    inEdit.remove(at: idx)
                }

                guard let newTargetIdx = inEdit.firstIndex(where: { $0.id == item.id }) else {
                    return false
                }

                let items = selectedWithIdx.map { $0.1 }
                var insertIdx = newTargetIdx
                for item in items {
                    inEdit.insert(item, at: insertIdx)
                    insertIdx += 1
                }
                tvm.items = inEdit

                dragCoordinator.dragCancelled()
                return true
            }

            guard let fromIdx = tvm.items.firstIndex(where: { $0.id == draggedId }),
                  let toIdx = tvm.items.firstIndex(where: { $0.id == item.id })
            else {
                return false
            }

            var inEdit = tvm.items
            let moved = inEdit.remove(at: fromIdx)
            let adjustedTo = fromIdx < toIdx ? toIdx - 1 : toIdx
            inEdit.insert(moved, at: adjustedTo)
            tvm.items = inEdit

            dragCoordinator.dragCancelled()
            return true
        }
        .scaleEffect(hover || dropTargeted ? 1.05 : 1.0)
        .onTapGesture(count: 2) {
            vm.notchClose()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if let text = item.textContent {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(text, forType: .string)
                } else {
                    NSWorkspace.shared.open(item.sourceURL)
                }
            }
        }
        .onTapGesture {
            let cmdDown = NSApp.currentEvent?.modifierFlags.contains(.command) == true
            if cmdDown {
                tvm.toggleSelection(item.id)
            } else {
                tvm.selectOnly(item.id)
            }
        }
    }
}

private struct DragSourceOverlay: NSViewRepresentable {
    let item: TrayDrop.DropItem
    let onDragStarted: () -> Void
    let onDragEnded: () -> Void

    func makeNSView(context: Context) -> DragSourceView {
        DragSourceView()
    }

    func updateNSView(_ nsView: DragSourceView, context: Context) {
        nsView.item = item
        nsView.onDragStarted = onDragStarted
        nsView.onDragEnded = onDragEnded
    }
}

private final class DragSourceView: NSView, NSDraggingSource {
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
