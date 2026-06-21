import SwiftUI

struct TrayPluginZone: View {
    @ObservedObject var dragCoordinator = ItemDragCoordinator.shared
    @StateObject var pluginManager = PluginManager.shared
    @StateObject var tvm = TrayDrop.shared

    var body: some View {
        ForEach(Array(pluginManager.enabledPlugins), id: \.id) { plugin in
            PluginDropTarget(plugin: plugin)
        }
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
        VStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 8)
                .fill(plugin.tint.opacity(isHovered ? 0.3 : 0.06))
                .overlay {
                    Image(systemName: plugin.icon)
                        .font(.title2)
                        .foregroundStyle(.white.opacity(isHovered ? 1 : 0.35))
                }
                .aspectRatio(1, contentMode: .fit)
                .frame(maxWidth: 64)

            Text(plugin.name)
                .multilineTextAlignment(.center)
                .font(.system(.footnote, design: .rounded))
                .foregroundStyle(.white.opacity(isHovered ? 1 : 0.35))
                .frame(maxWidth: 64)
        }
        .contentShape(Rectangle())
        .scaleEffect(isHovered ? 1.05 : 1.0)
        .padding(.leading, 8)
        .onDrop(of: supportedDropTypes, isTargeted: $isHovered) { providers in
            plugin.onDrop(providers: providers, itemIDs: draggedIDs)
            dragCoordinator.dragCancelled()
            return true
        }
        .animation(.easeOut(duration: 0.15), value: isHovered)
    }
}
