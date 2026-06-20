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
    @ObservedObject var dragCoordinator = ItemDragCoordinator.shared

    @State var hover = false

    private var visible: Bool {
        !isInitialBatch || index < cascadeCount
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
        .opacity(visible ? 1 : 0)
        .offset(y: visible ? 0 : -16)
        .animation(vm.animationInsert, value: visible)
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
        .onTapGesture {
            guard !vm.optionKeyPressed else { return }
            vm.notchClose()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                NSWorkspace.shared.open(item.sourceURL)
            }
        }
    }
}
