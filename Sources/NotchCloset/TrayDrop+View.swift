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
            .onDrop(of: [.data, .directory, .folder], isTargeted: $targeting) { providers in
                DispatchQueue.global().async { tvm.load(providers) }
                return true
            }
            .onAppear { tvm.cleanExpiredFiles() }
            .onChange(of: tvm.items.count) { _, _ in tvm.cleanExpiredFiles() }
            .onAppear { dragCoordinator.dragCancelled() }
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
            .animation(vm.animation, value: tvm.items)
            .animation(vm.animation, value: tvm.isLoading)
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
            NSLocalizedString("Press Option to delete", comment: ""),
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
                            ForEach(tvm.items) { item in
                                DropItemView(item: item, vm: vm, tvm: tvm)
                            }
                        }
                        .padding(vm.spacing)
                    }
                    .padding(-vm.spacing)
                    .scrollIndicators(.never)

                    if dragCoordinator.isDragging {
                        trashArea
                            .transition(.move(edge: .trailing).combined(with: .opacity))
                    }
                }
            }
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
        .onDrop(of: [.data, .directory, .folder], isTargeted: $trashHover) { _ in
            if let id = dragCoordinator.draggedItemId {
                tvm.delete(id)
                dragCoordinator.dragCancelled()
            }
            return true
        }
        .animation(vm.animation, value: trashHover)
    }
}

#Preview {
    NotchContentView(vm: .init())
        .padding()
        .frame(width: 550, height: 150, alignment: .center)
        .background(.black)
        .preferredColorScheme(.dark)
}
