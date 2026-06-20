//
//  TrayDrop+DropItem.swift
//  NotchCloset
//
//  Created by 秋星桥 on 2024/7/8.
//  Modified by @kanade2511 — reference-based (no file copy)
//

import Cocoa
import Foundation
import QuickLook
import UniformTypeIdentifiers

extension TrayDrop {
    struct DropItem: Identifiable, Codable, Equatable, Hashable {
        let id: UUID

        let fileName: String
        let size: Int
        /// Original file URL from the drag source.
        let sourceURL: URL

        let addedDate: Date
        let workspacePreviewImageData: Data

        init(url: URL) throws {
            assert(!Thread.isMainThread)

            id = UUID()
            fileName = url.lastPathComponent
            sourceURL = url

            size = (try? url.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
            addedDate = Date()
            workspacePreviewImageData = url.snapshotPreview().pngRepresentation
        }
    }
}

extension TrayDrop.DropItem {
    var workspacePreviewImage: NSImage {
        .init(data: workspacePreviewImageData) ?? .init()
    }

    var shouldClean: Bool {
        !FileManager.default.fileExists(atPath: sourceURL.path)
    }
}
