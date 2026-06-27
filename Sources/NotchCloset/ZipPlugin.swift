//
//  ZipPlugin.swift
//  NotchCloset
//

import Cocoa
import SwiftUI

class ZipPlugin: ObservableObject, NotchPlugin {
    var id: String { "zip" }
    var name: String { NSLocalizedString("Zip", comment: "") }
    var description: String { NSLocalizedString("Compress files into ZIP archive", comment: "") }
    var icon: String { "archivebox" }
    var tint: Color { .brown }

    @PublishedPersist(key: "zip_enabled", defaultValue: true)
    var isEnabled: Bool

    @Published var isProcessing = false
    @Published var isHovered = false

    func onDropTargeted(hover: Bool) {
        isHovered = hover
    }

    func onDrop(providers: [NSItemProvider], itemIDs: [TrayDrop.DropItem.ID]) {
        // External drop (providers only, no itemIDs) is not supported
        guard !itemIDs.isEmpty else { return }

        isProcessing = true

        Task {
            defer {
                Task { @MainActor in
                    self.isProcessing = false
                }
            }

            // Collect source URLs from the tray items
            var sourceURLs: [URL] = []
            for id in itemIDs {
                guard let item = TrayDrop.shared.items.first(where: { $0.id == id }),
                      !item.isText, !item.isWebURL,
                      let url = item.accessSource({ $0 })
                else { continue }
                sourceURLs.append(url)
            }

            guard !sourceURLs.isEmpty else { return }

            // Determine output path
            let outputURL: URL
            if sourceURLs.count == 1 {
                // Single file: save zip alongside the source file
                let source = sourceURLs[0]
                let dir = source.deletingLastPathComponent()
                let baseName = source.deletingPathExtension().lastPathComponent
                outputURL = dir.appendingPathComponent("\(baseName).zip")
            } else {
                // Multiple files: save zip to Desktop with timestamp
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyyMMdd-HHmmss"
                let timestamp = formatter.string(from: Date())
                let desktop = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first!
                outputURL = desktop.appendingPathComponent("NotchCloset-\(timestamp).zip")
            }

            // Remove existing file if present
            if FileManager.default.fileExists(atPath: outputURL.path) {
                try? FileManager.default.removeItem(at: outputURL)
            }

            // Run /usr/bin/zip
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/zip")
            process.arguments = ["-j", outputURL.path] + sourceURLs.map(\.path)

            do {
                try process.run()
                process.waitUntilExit()

                guard process.terminationStatus == 0 else {
                    await MainActor.run {
                        NSAlert.popError(
                            NSLocalizedString("Zip compression failed", comment: "")
                        )
                    }
                    return
                }

                // Create DropItem off the main thread (init asserts !isMainThread)
                let dropItem = try? TrayDrop.DropItem(url: outputURL)

                await MainActor.run {
                    if let dropItem {
                        TrayDrop.shared.items.updateOrInsert(dropItem, at: 0)
                    }
                }
            } catch {
                await MainActor.run {
                    NSAlert.popError(error)
                }
            }
        }
    }

    func contextMenuItems(for item: TrayDrop.DropItem) -> [PluginMenuItem] {
        // Only show for non-text, non-webURL file items
        guard !item.isText, !item.isWebURL else { return [] }

        return [
            PluginMenuItem(
                title: NSLocalizedString("Compress to ZIP", comment: ""),
                icon: "archivebox",
                action: { [weak self] in
                    self?.onDrop(providers: [], itemIDs: [item.id])
                }
            )
        ]
    }

    func dropTargetLabel(count: Int) -> String {
        let format = NSLocalizedString("Zip %d items", comment: "")
        return String.localizedStringWithFormat(format, count)
    }
}
