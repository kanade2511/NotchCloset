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

    private var visible: Bool {
        !isInitialBatch || index < cascadeCount
    }

    var body: some View {
        VStack {
            Image(nsImage: item.workspacePreviewImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: 80, maxHeight: 56)
            Text(item.fileName)
                .multilineTextAlignment(.center)
                .font(.system(.footnote, design: .rounded))
                .frame(maxWidth: 80)
                .lineLimit(2)
                .frame(minHeight: 28, alignment: .top)
        }
        .frame(width: 84, height: 108)
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
        .onDrag {
            dragCoordinator.dragStarted(itemId: item.id)

            if let text = item.textContent {
                let provider = NSItemProvider(object: text as NSString)
                provider.suggestedName = item.fileName
                return provider
            }

            let sourceURL = item.sourceURL

            if item.isWebURL {
                let provider = NSItemProvider(object: sourceURL as NSURL)
                provider.suggestedName = item.fileName
                return provider
            }

            let provider = NSItemProvider()
            provider.suggestedName = item.fileName

            let uti = (try? sourceURL.resourceValues(forKeys: [.typeIdentifierKey]))?.typeIdentifier
                ?? UTType.data.identifier

            provider.registerFileRepresentation(
                forTypeIdentifier: uti,
                visibility: .all
            ) { completion in
                _ = sourceURL.startAccessingSecurityScopedResource()
                defer { sourceURL.stopAccessingSecurityScopedResource() }
                completion(sourceURL, true, nil)
                return nil
            }

            provider.registerObject(sourceURL as NSURL, visibility: .all)
            return provider
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
