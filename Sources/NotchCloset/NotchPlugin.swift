import SwiftUI

struct PluginMenuItem {
    let title: String
    let icon: String
    let action: () -> Void
}

protocol NotchPlugin: Identifiable {
    var id: String { get }
    var name: String { get }
    var description: String { get }
    var icon: String { get }
    var tint: Color { get }
    var isEnabled: Bool { get set }

    func onDropTargeted(hover: Bool)
    func onDrop(providers: [NSItemProvider], itemIDs: [TrayDrop.DropItem.ID])
    func contextMenuItems(for item: TrayDrop.DropItem) -> [PluginMenuItem]
    func dropTargetLabel(count: Int) -> String
}
