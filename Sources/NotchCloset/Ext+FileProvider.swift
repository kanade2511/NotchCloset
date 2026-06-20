//
//  Ext+FileProvider.swift
//  NotchCloset
//
//  Created by 秋星桥 on 2024/7/8.
//  Modified by @kanade2511 — pass original URL directly
//

import Cocoa
import Foundation
import UniformTypeIdentifiers

extension NSItemProvider {
    func resolveFileURL() -> URL? {
        var url: URL?
        let sem = DispatchSemaphore(value: 0)

        _ = loadObject(ofClass: URL.self) { item, _ in
            defer { sem.signal() }
            guard let fileURL = item,
                  fileURL.isFileURL || fileURL.scheme == "file"
            else { return }
            url = fileURL
        }
        sem.wait()

        if url == nil {
            loadInPlaceFileRepresentation(
                forTypeIdentifier: UTType.data.identifier
            ) { input, _, _ in
                defer { sem.signal() }
                guard let input, input.isFileURL else { return }
                url = input
            }
            sem.wait()
        }

        if url == nil {
            loadInPlaceFileRepresentation(
                forTypeIdentifier: UTType.directory.identifier
            ) { input, _, _ in
                defer { sem.signal() }
                guard let input, input.isFileURL else { return }
                url = input
            }
            sem.wait()
        }

        return url
    }

    func resolveAnyURL() -> URL? {
        var url: URL?
        let sem = DispatchSemaphore(value: 0)

        _ = loadObject(ofClass: URL.self) { item, _ in
            defer { sem.signal() }
            guard let anyURL = item else { return }
            url = anyURL
        }
        sem.wait()

        if url == nil {
            _ = loadObject(ofClass: String.self) { item, _ in
                defer { sem.signal() }
                guard let text = item?.trimmingCharacters(in: .whitespacesAndNewlines),
                      let detectedURL = URL(string: text),
                      detectedURL.scheme == "http" || detectedURL.scheme == "https"
                else { return }
                url = detectedURL
            }
            sem.wait()
        }

        if url == nil {
            url = resolveFileURL()
        }

        return url
    }

    func resolveText() -> String? {
        var text: String?
        let sem = DispatchSemaphore(value: 0)

        _ = loadObject(ofClass: String.self) { item, _ in
            defer { sem.signal() }
            guard let string = item,
                  !string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            else { return }
            text = string
        }
        sem.wait()

        if text == nil {
            loadItem(forTypeIdentifier: UTType.plainText.identifier) { item, _ in
                defer { sem.signal() }
                guard let data = item as? Data,
                      let string = String(data: data, encoding: .utf8),
                      !string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                else { return }
                text = string
            }
            sem.wait()
        }

        if text == nil {
            loadItem(forTypeIdentifier: UTType.utf8PlainText.identifier) { item, _ in
                defer { sem.signal() }
                guard let data = item as? Data,
                      let string = String(data: data, encoding: .utf8),
                      !string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                else { return }
                text = string
            }
            sem.wait()
        }

        return text
    }
}
