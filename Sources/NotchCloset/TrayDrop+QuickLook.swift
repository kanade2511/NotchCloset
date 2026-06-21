//
//  TrayDrop+QuickLook.swift
//  NotchCloset
//

import Cocoa
import Quartz

final class QuickLookHelper: NSObject, QLPreviewPanelDataSource, QLPreviewPanelDelegate {
    static let shared = QuickLookHelper()

    private let tvm: TrayDrop = .shared

    func numberOfPreviewItems(in panel: QLPreviewPanel!) -> Int {
        tvm.selectedIDs.isEmpty ? 0 : tvm.selectedIDs.count
    }

    func previewPanel(_ panel: QLPreviewPanel!, previewItemAt index: Int) -> QLPreviewItem! {
        let ids = Array(tvm.selectedIDs)
        guard index < ids.count,
              let item = tvm.items.first(where: { $0.id == ids[index] })
        else { return nil }
        if let url = item.accessSource({ $0 as NSURL }) {
            return url
        }
        return item.sourceURL as NSURL
    }

    func previewPanel(_ panel: QLPreviewPanel!, handle event: NSEvent!) -> Bool {
        return false
    }

    func toggle() {
        guard let panel = QLPreviewPanel.shared() else { return }
        if panel.isVisible {
            panel.orderOut(self)
        } else {
            panel.dataSource = self
            panel.delegate = self
            panel.makeKeyAndOrderFront(self)
        }
    }
}
