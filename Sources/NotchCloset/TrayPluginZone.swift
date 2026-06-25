import SwiftUI

struct TrayPluginZone: View {
    @ObservedObject var dragCoordinator = ItemDragCoordinator.shared
    @StateObject var pluginManager = PluginManager.shared
    @StateObject var tvm = TrayDrop.shared

    var body: some View {
        HStack(spacing: 8) {
            if pluginManager.isEnabled(pluginId: "airdrop") {
                PluginDropTarget(plugin: airDropPlugin)
            }
            if pluginManager.isEnabled(pluginId: "ocr") {
                PluginDropTarget(plugin: ocrPlugin)
            }
        }
    }

    private var airDropPlugin: AirDropPlugin {
        pluginManager.plugin(for: "airdrop") as! AirDropPlugin
    }
    private var ocrPlugin: OCRPlugin {
        pluginManager.plugin(for: "ocr") as! OCRPlugin
    }
}

struct PluginDropTarget: View {
    let plugin: any NotchPlugin
    @ObservedObject var dragCoordinator = ItemDragCoordinator.shared
    @ObservedObject var tvm = TrayDrop.shared
    @State private var isHovered = false

    private var draggedIDs: [TrayDrop.DropItem.ID] {
        guard let draggedId = dragCoordinator.draggedItemId else { return [] }
        if tvm.selectedIDs.contains(draggedId), tvm.selectedIDs.count > 1 {
            return Array(tvm.selectedIDs)
        }
        return [draggedId]
    }

    var body: some View {
        VStack(spacing: 6) {
            ActionTile(
                icon: plugin.icon,
                label: plugin.name,
                tint: plugin.tint,
                isHovered: isHovered
            )
        }
        .padding(10)
        .background {
            RoundedRectangle(cornerRadius: 10)
                .fill(.white.opacity(0.05))
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [6]))
                .foregroundStyle(.white.opacity(0.12))
        }
        .scaleEffect(isHovered ? 1.05 : 1.0)
        .onDrop(of: supportedDropTypes, isTargeted: $isHovered) { providers in
            plugin.onDrop(providers: providers, itemIDs: draggedIDs)
            dragCoordinator.dragCancelled()
            return true
        }
        .animation(.easeOut(duration: 0.15), value: isHovered)
    }
}
