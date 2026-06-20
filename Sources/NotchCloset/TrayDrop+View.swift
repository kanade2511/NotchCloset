//
//  TrayDrop+View.swift
//  NotchCloset
//
//  Created by 秋星桥 on 2024/7/8.
//

import SwiftUI

struct TrayView: View {
    @StateObject var vm: NotchViewModel
    @StateObject var tvm = TrayDrop.shared
    @ObservedObject var dragCoordinator = ItemDragCoordinator.shared

    @State private var targeting = false
    @State private var trashHover = false
    @State private var initialBatchEnd = 0
    @State private var cascadeCount = 0
    @State private var cascadeDidRun = false

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
                                }

                                if dragCoordinator.isDragging {
                                    endDropZone
                                }
                        }
                        .padding(vm.spacing)
                    }
                    .padding(-vm.spacing)
                    .scrollIndicators(.never)

                    if dragCoordinator.isDragging {
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
                guard let draggedId = dragCoordinator.draggedItemId,
                      let fromIdx = tvm.items.firstIndex(where: { $0.id == draggedId })
                else {
                    return false
                }
                var inEdit = tvm.items
                let moved = inEdit.remove(at: fromIdx)
                inEdit.append(moved)
                tvm.items = inEdit
                dragCoordinator.dragCancelled()
                return true
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
                tvm.delete(id)
                dragCoordinator.dragCancelled()
            }
            return true
        }
        .animation(vm.animationHover, value: trashHover)
    }
}

#Preview {
    NotchContentView(vm: .init())
        .padding()
        .frame(width: 550, height: 150, alignment: .center)
        .background(.black)
        .preferredColorScheme(.dark)
}
