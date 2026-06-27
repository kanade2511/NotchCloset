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
        let textContent: String?
        let bookmarkData: Data?

        let addedDate: Date
        var workspacePreviewImageData: Data

        var isWebURL: Bool {
            sourceURL.scheme == "http" || sourceURL.scheme == "https"
        }

        var isText: Bool {
            textContent != nil
        }

        init(url: URL, bookmarkData: Data? = nil) throws {
            assert(!Thread.isMainThread)

            id = UUID()
            sourceURL = url
            addedDate = Date()
            textContent = nil

            if url.scheme == "http" || url.scheme == "https" {
                fileName = url.host ?? url.absoluteString
                size = 0
                self.bookmarkData = nil
                workspacePreviewImageData = Self.globeIcon().pngRepresentation
            } else {
                fileName = url.lastPathComponent
                size = (try? url.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
                self.bookmarkData = bookmarkData
                workspacePreviewImageData = url.snapshotPreview().pngRepresentation
            }
        }

        init(text: String) {
            id = UUID()
            let snippet = String(text.prefix(80))
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: "\n", with: " ")
            fileName = snippet.isEmpty ? "Text" : snippet
            size = text.utf8.count
            sourceURL = URL(string: "opaque://text/\(id.uuidString)")!
            addedDate = Date()
            bookmarkData = nil
            workspacePreviewImageData = Self.textQuoteIcon().pngRepresentation
            textContent = text
        }

        private static func globeIcon() -> NSImage {
            let config = NSImage.SymbolConfiguration(pointSize: 64, weight: .light)
            return NSImage(systemSymbolName: "globe", accessibilityDescription: nil)?
                .withSymbolConfiguration(config) ?? NSImage()
        }

        private static func textQuoteIcon() -> NSImage {
            let config = NSImage.SymbolConfiguration(pointSize: 64, weight: .light)
            return NSImage(systemSymbolName: "character.cursor.ibeam", accessibilityDescription: nil)?
                .withSymbolConfiguration(config) ?? NSImage()
        }
    }
}

extension TrayDrop.DropItem {
    var workspacePreviewImage: NSImage {
        .init(data: workspacePreviewImageData) ?? .init()
    }

    var shouldClean: Bool {
        if isText || isWebURL { return false }
        if let data = bookmarkData {
            var stale = false
            guard let url = try? URL(
                resolvingBookmarkData: data,
                options: [],
                relativeTo: nil,
                bookmarkDataIsStale: &stale
            ), !stale else { return true }
            let started = url.startAccessingSecurityScopedResource()
            defer { if started { url.stopAccessingSecurityScopedResource() } }
            return !FileManager.default.fileExists(atPath: url.path)
        }
        return !FileManager.default.fileExists(atPath: sourceURL.path)
    }
}

// MARK: - AppKit Extensions (inlined from separate files)

extension NSImage {
    var pngRepresentation: Data {
        guard let cgImage = cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return .init()
        }
        let imageRep = NSBitmapImageRep(cgImage: cgImage)
        imageRep.size = size
        return imageRep.representation(using: .png, properties: [:]) ?? .init()
    }
}

extension URL {
    func snapshotPreview() -> NSImage {
        if let preview = QLThumbnailImageCreate(
            kCFAllocatorDefault,
            self as CFURL,
            CGSize(width: 128, height: 128),
            nil
        )?.takeRetainedValue() {
            return NSImage(cgImage: preview, size: .zero)
        }
        return NSWorkspace.shared.icon(forFile: path)
    }
}
