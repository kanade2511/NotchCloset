//
//  TrayDrop+View.swift
//  NotchCloset
//
//  Created by 秋星桥 on 2024/7/8.
//

import SwiftUI
import AppKit

struct ItemFramePreference: PreferenceKey {
    static var defaultValue: [TrayDrop.DropItem.ID: CGRect] = [:]
    static func reduce(value: inout [TrayDrop.DropItem.ID: CGRect], nextValue: () -> [TrayDrop.DropItem.ID: CGRect]) {
        value.merge(nextValue()) { $1 }
    }
}

struct TrayView: View {
    @StateObject var vm: NotchViewModel
    @StateObject var tvm = TrayDrop.shared
    @ObservedObject var dragCoordinator = ItemDragCoordinator.shared

    @State private var targeting = false
    @State private var trashHover = false
    @State private var initialBatchEnd = 0
    @State private var cascadeCount = 0
    @State private var cascadeDidRun = false
    @State private var itemFrames: [TrayDrop.DropItem.ID: CGRect] = [:]

    var storageTime: String {
        switch tvm.selectedFileStorageTime {
        case .oneHour:
            return NSLocalizedString("an hour", comment: "")
        case .oneDay:
            return NSLocalizedString("a day", comment: "")
        case .twoDays:
            return NSLocalizedString("two days", comment: "")
        case .threeDays:
            return NSLocalizedString("three days", comment: "")
        case .oneWeek:
            return NSLocalizedString("a week", comment: "")
        case .never:
            return NSLocalizedString("forever", comment: "")
        case .custom:
            let localizedTimeUnit = NSLocalizedString(tvm.customStorageTimeUnit.localized.lowercased(), comment: "")
            return "\(tvm.customStorageTime) \(localizedTimeUnit)"
        }
    }

    var body: some View {
        panel
            .onDrop(of: [.data, .directory, .folder, .url, .text, .plainText, .utf8PlainText], isTargeted: $targeting) { providers in
                guard dragCoordinator.draggedItemId == nil else {
                    dragCoordinator.dragCancelled()
                    return true
                }
                DispatchQueue.global().async { tvm.load(providers) }
                return true
            }
            .onAppear {
                guard !cascadeDidRun else { return }
                cascadeDidRun = true

                tvm.cleanExpiredFiles()
                initialBatchEnd = tvm.items.count
                cascadeCount = 0
                var step = 0
                let maxItems = tvm.items.count
                if maxItems > 0 {
                    Timer.scheduledTimer(withTimeInterval: 0.12, repeats: true) { timer in
                        step += 1
                        cascadeCount = step
                        if step >= maxItems {
                            timer.invalidate()
                        }
                    }
                }
            }
            .onChange(of: tvm.items.count) { _, _ in tvm.cleanExpiredFiles() }
    }

    var panel: some View {
        RoundedRectangle(cornerRadius: vm.cornerRadius)
            .strokeBorder(style: StrokeStyle(lineWidth: 4, dash: [10]))
            .foregroundStyle(.white.opacity(0.1))
            .background(loading)
            .overlay {
                content
                    .padding()
            }
            .animation(vm.animationContent, value: tvm.items)
            .animation(vm.animationContent, value: tvm.isLoading)
    }

    var loading: some View {
        RoundedRectangle(cornerRadius: vm.cornerRadius)
            .foregroundStyle(.white.opacity(0.1))
    }

    var text: String {
        [
            String(
                format: NSLocalizedString("Drag files here to keep them for %@", comment: ""),
                storageTime
            ),
            "&",
            NSLocalizedString("Hover to delete", comment: ""),
        ].joined(separator: " ")
    }

    var content: some View {
        Group {
            if tvm.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "tray.and.arrow.down.fill")
                    Text(text)
                        .multilineTextAlignment(.center)
                        .font(.system(.headline, design: .rounded))
                }
            } else {
                HStack(spacing: 0) {
                    ScrollView(.horizontal) {
                        HStack(spacing: vm.spacing) {
                                ForEach(Array(tvm.items.enumerated()), id: \.element.id) { idx, item in
                                    DropItemView(
                                        item: item,
                                        index: idx,
                                        total: tvm.items.count,
                                        isInitialBatch: idx < initialBatchEnd,
                                        cascadeCount: cascadeCount,
                                        vm: vm,
                                        tvm: tvm
                                    )
                                    .background(GeometryReader { geo in
                                        Color.clear.preference(
                                            key: ItemFramePreference.self,
                                            value: [item.id: geo.frame(in: .named("content"))]
                                        )
                                    })
                                }

                                if dragCoordinator.isDragging {
                                    endDropZone
                                }
                        }
                        .padding(vm.spacing)
                        .coordinateSpace(name: "content")
                        .background(SelectionOverlay(itemFrames: itemFrames))
                    }
                    .padding(-vm.spacing)
                    .scrollIndicators(.never)
                    .onTapGesture {
                        tvm.clearSelection()
                    }
                    .onPreferenceChange(ItemFramePreference.self) { frames in
                        itemFrames = frames
                    }

                    if tvm.selectedIDs.count > 1 {
                        deleteSelectedButton
                    } else if dragCoordinator.isDragging {
                        trashArea
                            .transition(.opacity.animation(vm.animationTrash))
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var endDropZone: some View {
        Color.clear
            .frame(width: 48, height: 64)
            .contentShape(Rectangle())
            .onDrop(of: [.data, .directory, .folder, .url, .text, .plainText, .utf8PlainText], isTargeted: .constant(false)) { _ in
                guard let draggedId = dragCoordinator.draggedItemId
                else {
                    return false
                }

                if tvm.selectedIDs.contains(draggedId), tvm.selectedIDs.count > 1 {
                    let selectedWithIdx: [(Int, TrayDrop.DropItem)] = tvm.items.enumerated()
                        .filter { tvm.selectedIDs.contains($0.element.id) }
                        .map { ($0.offset, $0.element) }

                    var inEdit = tvm.items
                    for (idx, _) in selectedWithIdx.reversed() {
                        inEdit.remove(at: idx)
                    }

                    let items = selectedWithIdx.map { $0.1 }
                    for item in items {
                        inEdit.append(item)
                    }
                    tvm.items = inEdit
                } else {
                    guard let fromIdx = tvm.items.firstIndex(where: { $0.id == draggedId })
                    else { return false }

                    var inEdit = tvm.items
                    let moved = inEdit.remove(at: fromIdx)
                    inEdit.append(moved)
                    tvm.items = inEdit
                }
                dragCoordinator.dragCancelled()
                return true
            }
    }

    @ViewBuilder
    private var deleteSelectedButton: some View {
        VStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 8)
                .fill(.red.opacity(0.06))
                .overlay {
                    Image(systemName: "trash")
                        .font(.title2)
                        .foregroundStyle(.white.opacity(0.7))
                }
                .aspectRatio(1, contentMode: .fit)
                .frame(maxWidth: 64)

            Text(String(format: NSLocalizedString("Delete %d", comment: ""), tvm.selectedIDs.count))
                .multilineTextAlignment(.center)
                .font(.system(.footnote, design: .rounded))
                .foregroundStyle(.white.opacity(0.7))
                .frame(maxWidth: 64)
        }
        .contentShape(Rectangle())
        .padding(.leading, vm.spacing)
        .onTapGesture {
            tvm.deleteSelected()
        }
    }

    @ViewBuilder
    private var trashArea: some View {
        VStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 8)
                .fill(.red.opacity(trashHover ? 0.3 : 0.06))
                .overlay {
                    Image(systemName: "trash")
                        .font(.title2)
                        .foregroundStyle(.white.opacity(trashHover ? 1 : 0.35))
                }
                .aspectRatio(1, contentMode: .fit)
                .frame(maxWidth: 64)

            Text("Delete")
                .multilineTextAlignment(.center)
                .font(.system(.footnote, design: .rounded))
                .foregroundStyle(.white.opacity(trashHover ? 1 : 0.35))
                .frame(maxWidth: 64)
        }
        .contentShape(Rectangle())
        .scaleEffect(trashHover ? 1.05 : 1.0)
        .padding(.leading, vm.spacing)
        .onDrop(of: [.data, .directory, .folder, .url, .text, .plainText, .utf8PlainText], isTargeted: $trashHover) { _ in
            if let id = dragCoordinator.draggedItemId {
                if tvm.selectedIDs.contains(id), tvm.selectedIDs.count > 1 {
                    tvm.deleteSelected()
                } else {
                    tvm.delete(id)
                }
                dragCoordinator.dragCancelled()
            }
            return true
        }
        .animation(vm.animationHover, value: trashHover)
    }
}

struct SelectionOverlay: NSViewRepresentable {
    var itemFrames: [TrayDrop.DropItem.ID: CGRect]

    func makeNSView(context: Context) -> SelectionOverlayView {
        SelectionOverlayView()
    }

    func updateNSView(_ nsView: SelectionOverlayView, context: Context) {
        nsView.itemFrames = itemFrames
    }
}

class SelectionOverlayView: NSView {
    var itemFrames: [TrayDrop.DropItem.ID: CGRect] = [:]

    private var dragStart: NSPoint = .zero
    private var dragCurrent: NSPoint = .zero
    private var isDragging = false
    private let minimumDragDistance: CGFloat = 4

    override func mouseDown(with event: NSEvent) {
        dragStart = convert(event.locationInWindow, from: nil)
        dragCurrent = dragStart
        isDragging = false
    }

    override func mouseDragged(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        dragCurrent = point

        let dx = abs(point.x - dragStart.x)
        let dy = abs(point.y - dragStart.y)

        if dx > minimumDragDistance || dy > minimumDragDistance {
            if !isDragging {
                isDragging = true
                TrayDrop.shared.clearSelection()
            }
        }

        if isDragging {
            selectIntersectingItems()
        }
    }

    override func mouseUp(with event: NSEvent) {
        if isDragging {
            selectIntersectingItems()
        } else {
            TrayDrop.shared.clearSelection()
        }
        isDragging = false
        dragStart = .zero
        dragCurrent = .zero
    }

    private var currentRect: CGRect {
        let minX = min(dragStart.x, dragCurrent.x)
        let maxX = max(dragStart.x, dragCurrent.x)
        let minY = min(dragStart.y, dragCurrent.y)
        let maxY = max(dragStart.y, dragCurrent.y)
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }

    private func selectIntersectingItems() {
        let rect = currentRect
        guard !rect.isEmpty else { return }
        let ids = itemFrames.compactMap { id, frame in
            frame.intersects(rect) ? id : nil
        }
        if !ids.isEmpty {
            TrayDrop.shared.selectedIDs = Set(ids)
        }
    }
}

#Preview {
    NotchContentView(vm: .init())
        .padding()
        .frame(width: 550, height: 150, alignment: .center)
        .background(.black)
        .preferredColorScheme(.dark)
}
