import SwiftUI

struct TrayPluginZone: View {
    @ObservedObject var dragCoordinator = ItemDragCoordinator.shared
    @StateObject var pluginManager = PluginManager.shared
    @StateObject var tvm = TrayDrop.shared

    var body: some View {
        HStack(spacing: 8) {
            ForEach(Array(pluginManager.enabledPlugins), id: \.id) { plugin in
                PluginDropTarget(plugin: plugin)
            }
        }
        .padding(.leading, 8)
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
        RoundedRectangle(cornerRadius: 8)
            .fill(plugin.tint.opacity(isHovered ? 0.3 : 0.1))
            .frame(width: 48, height: 64)
            .overlay {
                Image(systemName: plugin.icon)
                    .font(.title2)
                    .foregroundStyle(plugin.tint.opacity(isHovered ? 1 : 0.5))
            }
            .contentShape(Rectangle())
            .scaleEffect(isHovered ? 1.05 : 1.0)
            .onDrop(of: supportedDropTypes, isTargeted: $isHovered) { providers in
                plugin.onDrop(providers: providers, itemIDs: draggedIDs)
                dragCoordinator.dragCancelled()
                return true
            }
            .animation(.easeOut(duration: 0.15), value: isHovered)
    }
}
