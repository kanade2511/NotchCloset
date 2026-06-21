//
//  Ext+Bookmark.swift
//  NotchCloset
//

import Foundation

extension TrayDrop.DropItem {
    func accessSource<T>(_ block: (URL) throws -> T) rethrows -> T? {
        if isText || isWebURL { return try? block(sourceURL) }
        if let data = bookmarkData {
            var stale = false
            guard let url = try? URL(
                resolvingBookmarkData: data,
                options: [],
                relativeTo: nil,
                bookmarkDataIsStale: &stale
            ), !stale else { return nil }
            let started = url.startAccessingSecurityScopedResource()
            defer { if started { url.stopAccessingSecurityScopedResource() } }
            return try? block(url)
        }
        let started = sourceURL.startAccessingSecurityScopedResource()
        defer { if started { sourceURL.stopAccessingSecurityScopedResource() } }
        return try? block(sourceURL)
    }
}
