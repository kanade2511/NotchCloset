//
//  TrayDrop+View.swift
//  NotchCloset
//
//  Created by 秋星桥 on 2024/7/8.
//

import SwiftUI
import AppKit

struct TrayView: View {
    @StateObject var vm: NotchViewModel
    @ObservedObject var tvm = TrayDrop.shared
    @ObservedObject var dragCoordinator = ItemDragCoordinator.shared
    @ObservedObject var pluginManager = PluginManager.shared

    @State private var targeting = false
    @State private var trashHover = false
    @State private var initialBatchEnd = 0
    @State private var cascadeCount = 0
    @State private var cascadeDidRun = false
    @State private var itemFrames: [TrayDrop.DropItem.ID: CGRect] = [:]
    @State private var contentFrame: CGRect = .zero
    @State private var selectionStart: CGPoint?
    @State private var selectionEnd: CGPoint?
    @State private var isSelecting = false
    @State private var eventMonitor: Any?

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
            .onDrop(of: supportedDropTypes, isTargeted: $targeting) { providers in
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
            .onAppear {
                eventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .leftMouseDragged, .leftMouseUp]) { event in
                    guard !contentFrame.isEmpty else { return event }
                    let windowHeight = event.window?.frame.height ?? 0
                    let pointInWindow = CGPoint(
                        x: event.locationInWindow.x,
                        y: windowHeight - event.locationInWindow.y
                    )
                    let localPoint = CGPoint(
                        x: pointInWindow.x - contentFrame.minX,
                        y: pointInWindow.y - contentFrame.minY
                    )

                    switch event.type {
                    case .leftMouseDown:
                        let onItem = itemFrames.values.contains { $0.contains(localPoint) }
                        guard !onItem else { break }
                        selectionStart = localPoint
                        selectionEnd = localPoint
                        isSelecting = true
                        DispatchQueue.main.async { tvm.clearSelection() }
                    case .leftMouseDragged:
                        guard isSelecting else { break }
                        selectionEnd = localPoint
                        updateSelectionFromRect()
                    case .leftMouseUp:
                        guard isSelecting else { break }
                        isSelecting = false
                        selectionStart = nil
                        selectionEnd = nil
                    default:
                        break
                    }
                    return event
                }
            }
            .onDisappear {
                if let monitor = eventMonitor {
                    NSEvent.removeMonitor(monitor)
                    eventMonitor = nil
                }
            }
    }

    var panel: some View {
        content
            .animation(vm.contentAnimation, value: tvm.items)
            .animation(vm.contentAnimation, value: tvm.isLoading)
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
        HStack(spacing: 0) {
            if !pluginManager.enabledPlugins.isEmpty {
                TrayPluginZone()
                    .frame(maxHeight: .infinity)

                Spacer().frame(width: 8)
            }

            HStack(spacing: 0) {
                if tvm.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "tray.and.arrow.down.fill")
                        Text(text)
                            .multilineTextAlignment(.center)
                            .font(.system(.headline, design: .rounded))
                    }
                    .frame(maxWidth: .infinity)
                } else {
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
                        }
                        .padding(vm.spacing)
                    }
                    .coordinateSpace(name: "content")
                    .padding(-vm.spacing)
                    .scrollIndicators(.never)
                    .background(GeometryReader { geo in
                        Color.clear.onAppear {
                            contentFrame = geo.frame(in: .global)
                        }.onChange(of: geo.frame(in: .global)) { _, f in
                            contentFrame = f
                        }
                    })
                    .onTapGesture {
                        tvm.clearSelection()
                    }
                    .onPreferenceChange(ItemFramePreference.self) { frames in
                        itemFrames = frames
                    }
                    .overlay {
                        if isSelecting, let start = selectionStart, let end = selectionEnd {
                            let rect = selectionRect(from: start, to: end)
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(.blue.opacity(0.7), lineWidth: 1.5)
                                .frame(width: rect.width, height: rect.height)
                                .position(x: rect.midX, y: rect.midY)
                        }
                    }
                }

                if tvm.selectedIDs.count > 1 {
                    deleteSelectedButton
                } else if dragCoordinator.isDragging {
                    trashArea
                        .transition(.opacity.animation(vm.trashAnimation))
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
            .frame(maxHeight: .infinity)
            .background {
                RoundedRectangle(cornerRadius: 10)
                    .fill(.white.opacity(0.05))
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [6]))
                    .foregroundStyle(.white.opacity(0.12))
            }
        }
    }

    @ViewBuilder
    private var deleteSelectedButton: some View {
        Button {
            tvm.deleteSelected()
        } label: {
            ActionTile(
                icon: "trash",
                label: String(format: NSLocalizedString("Delete %d", comment: ""), tvm.selectedIDs.count),
                tint: .red
            )
        }
        .buttonStyle(.borderless)
        .padding(.leading, vm.spacing)
        .onDrop(of: supportedDropTypes, isTargeted: .constant(false)) { _ in
            tvm.deleteSelected()
            dragCoordinator.dragCancelled()
            return true
        }
    }

    @ViewBuilder
    private var trashArea: some View {
        ActionTile(
            icon: "trash",
            label: "Delete",
            tint: .red,
            isHovered: trashHover
        )
        .scaleEffect(trashHover ? 1.05 : 1.0)
        .padding(.leading, vm.spacing)
        .onDrop(of: supportedDropTypes, isTargeted: $trashHover) { _ in
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
        .animation(vm.hoverAnimation, value: trashHover)
    }

    private func selectionRect(from start: CGPoint, to end: CGPoint) -> CGRect {
        let minX = min(start.x, end.x)
        let minY = min(start.y, end.y)
        let maxX = max(start.x, end.x)
        let maxY = max(start.y, end.y)
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }

    private func updateSelectionFromRect() {
        guard let start = selectionStart, let end = selectionEnd else { return }
        let rect = selectionRect(from: start, to: end)
        guard !rect.isEmpty else { return }
        let ids = itemFrames.compactMap { id, frame in
            frame.intersects(rect) ? id : nil
        }
        if !ids.isEmpty {
            tvm.selectedIDs = Set(ids)
        }
    }
}

#Preview {
    TrayView(vm: .init())
        .padding()
        .frame(width: 550, height: 150, alignment: .center)
        .background(.black)
        .preferredColorScheme(.dark)
}
