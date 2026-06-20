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
        return url
    }
}

extension [NSItemProvider] {
    func interfaceConvert() -> [URL]? {
        let urls = compactMap { provider -> URL? in
            provider.resolveFileURL()
        }
        guard urls.count == count else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                NSAlert.popError(
                    NSLocalizedString("One or more files failed to load", comment: "")
                )
            }
            return nil
        }
        return urls
    }
}
