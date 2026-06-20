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
    @StateObject var vm: NotchViewModel
    @StateObject var tvm = TrayDrop.shared
    @ObservedObject var dragCoordinator = ItemDragCoordinator.shared

    @State var hover = false

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
        .contentShape(Rectangle())
        .transition(.asymmetric(
            insertion: .opacity.combined(with: .scale(scale: 0.85)),
            removal: .opacity
        ))
        .contentShape(Rectangle())
        .onHover { hover = $0 }
        .scaleEffect(hover ? 1.05 : 1.0)
        .animation(vm.animation, value: hover)
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
                .opacity(vm.optionKeyPressed ? 1 : 0)
                .scaleEffect(vm.optionKeyPressed ? 1 : 0.5)
                .animation(vm.animation, value: vm.optionKeyPressed)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .offset(x: vm.spacing / 2, y: -vm.spacing / 2)
                .onTapGesture { tvm.delete(item.id) }
        }
    }
}
