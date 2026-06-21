import Cocoa
import SwiftUI

class AirDropPlugin: ObservableObject, NotchPlugin {
    var id: String { "airdrop" }
    var name: String { NSLocalizedString("AirDrop", comment: "") }
    var description: String { NSLocalizedString("Share files via AirDrop", comment: "") }
    var icon: String { "airplayaudio" }
    var tint: Color { .blue }

    @PublishedPersist(key: "airdrop_enabled", defaultValue: true)
    var isEnabled: Bool

    @Published var isHovered = false

    func onDropTargeted(hover: Bool) {
        isHovered = hover
    }

    func onDrop(providers: [NSItemProvider], itemIDs: [TrayDrop.DropItem.ID]) {
        var urls: [URL] = []
        for id in itemIDs {
            if let item = TrayDrop.shared.items.first(where: { $0.id == id }),
               !item.isText, !item.isWebURL {
                if let url = item.accessSource({ $0 }) {
                    urls.append(url)
                }
            }
        }
        guard !urls.isEmpty else { return }

        let share = Share(files: urls, serviceName: .sendViaAirDrop)
        share.begin()

        if let delegate = NSApp.delegate as? AppDelegate,
           let vm = delegate.mainWindowController?.vm {
            vm.notchClose()
        }
    }

    func contextMenuItems(for item: TrayDrop.DropItem) -> [PluginMenuItem] {
        [
            PluginMenuItem(
                title: NSLocalizedString("Share via AirDrop", comment: ""),
                icon: "airplayaudio",
                action: { [weak self] in
                    self?.onDrop(providers: [], itemIDs: [item.id])
                }
            )
        ]
    }

    func dropTargetLabel(count: Int) -> String {
        let format = NSLocalizedString("AirDrop %d files", comment: "")
        return String.localizedStringWithFormat(format, count)
    }
}
