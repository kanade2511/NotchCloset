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

        var fileName: String
        let size: Int
        let sourceURL: URL

        let addedDate: Date
        var workspacePreviewImageData: Data

        var isWebURL: Bool {
            sourceURL.scheme == "http" || sourceURL.scheme == "https"
        }

        init(url: URL) throws {
            assert(!Thread.isMainThread)

            id = UUID()
            sourceURL = url
            addedDate = Date()

            if url.scheme == "http" || url.scheme == "https" {
                fileName = url.host ?? url.absoluteString
                size = 0
                workspacePreviewImageData = Self.globeIcon().pngRepresentation
            } else {
                fileName = url.lastPathComponent
                size = (try? url.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
                workspacePreviewImageData = url.snapshotPreview().pngRepresentation
            }
        }

        private static func globeIcon() -> NSImage {
            let config = NSImage.SymbolConfiguration(pointSize: 64, weight: .light)
            return NSImage(systemSymbolName: "globe", accessibilityDescription: nil)?
                .withSymbolConfiguration(config) ?? NSImage()
        }
    }
}

extension TrayDrop.DropItem {
    var workspacePreviewImage: NSImage {
        .init(data: workspacePreviewImageData) ?? .init()
    }

    var shouldClean: Bool {
        if isWebURL { return false }
        return !FileManager.default.fileExists(atPath: sourceURL.path)
    }
}
