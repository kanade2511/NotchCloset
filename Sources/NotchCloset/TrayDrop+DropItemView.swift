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
    @StateObject var vm: NotchViewModel
    @StateObject var tvm = TrayDrop.shared
    @ObservedObject var dragCoordinator = ItemDragCoordinator.shared

    @State var hover = false
    @State private var appeared = false

    private var insertionDelay: Double {
        isInitialBatch ? (0.08 + Double(index) * 0.20) : 0.03
    }

    var body: some View {
        VStack {
            Image(nsImage: item.workspacePreviewImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: 64)
            Text(item.fileName)
                .multilineTextAlignment(.center)
                .font(.system(.footnote, design: .rounded))
                .frame(maxWidth: 64)
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : -16)
        .animation(vm.animationInsert, value: appeared)
        .task {
            try? await Task.sleep(nanoseconds: UInt64(insertionDelay * 1_000_000_000))
            appeared = true
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : -16)
        .scaleEffect(appeared ? 1 : 0.85)
        .onAppear {
            let delay = isInitialBatch ? Double(index) * 0.10 : 0
            withAnimation(vm.animationInsert.delay(delay)) { appeared = true }
        }
        .contentShape(Rectangle())
        .transition(.asymmetric(
            insertion: .identity,
            removal: .opacity
                .animation(vm.animationRemove.delay(Double(total - 1 - index) * 0.04))
        ))
        .onHover { hover = $0 }
        .scaleEffect(hover ? 1.05 : 1.0)
        .animation(vm.animationHover, value: hover)
        .onDrag {
            dragCoordinator.dragStarted(itemId: item.id)
            let sourceURL = item.sourceURL
            let isDir = (try? sourceURL.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory ?? false
            let provider = NSItemProvider()
            provider.suggestedName = item.fileName
            let utType: UTType = isDir ? .directory : .data
            provider.registerFileRepresentation(
                for: utType,
                visibility: .all
            ) { completion in
                _ = sourceURL.startAccessingSecurityScopedResource()
                defer { sourceURL.stopAccessingSecurityScopedResource() }

                let tempDir = temporaryDirectory
                    .appendingPathComponent(UUID().uuidString)
                try? FileManager.default.createDirectory(
                    at: tempDir,
                    withIntermediateDirectories: true
                )
                let tempURL = tempDir
                    .appendingPathComponent(item.fileName)

                let fm = FileManager.default
                do {
                    try fm.moveItem(at: sourceURL, to: tempURL)
                } catch {
                    try? fm.copyItem(at: sourceURL, to: tempURL)
                    try? fm.removeItem(at: sourceURL)
                }
                completion(tempURL, false, nil)

                DispatchQueue.main.async {
                    guard dragCoordinator.draggedItemId == item.id else { return }
                    TrayDrop.shared.delete(item.id)
                    dragCoordinator.dragCompleted(itemId: item.id)
                }
                return nil
            }
            return provider
        }
        .onTapGesture {
            guard !vm.optionKeyPressed else { return }
            vm.notchClose()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                NSWorkspace.shared.open(item.sourceURL)
            }
        }
        .overlay {
            Image(systemName: "xmark.circle.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundStyle(.red)
                .background(Color.white.clipShape(Circle()).padding(1))
                .frame(width: vm.spacing, height: vm.spacing)
                .opacity(hover ? 1 : 0)
                .scaleEffect(hover ? 1 : 0.5)
                .animation(vm.animationHover, value: hover)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .offset(x: vm.spacing / 2, y: -vm.spacing / 2)
                .onTapGesture { tvm.delete(item.id) }
        }
    }
}
