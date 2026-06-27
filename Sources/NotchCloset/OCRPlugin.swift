//
//  OCRPlugin.swift
//  NotchCloset
//
//  Created by 秋星桥 on 2025/6/25.
//

import Cocoa
import SwiftUI
import Vision

class OCRPlugin: ObservableObject, NotchPlugin {
    var id: String { "ocr" }
    var name: String { NSLocalizedString("OCR", comment: "") }
    var description: String { NSLocalizedString("Create searchable PDFs", comment: "") }
    var icon: String { "text.viewfinder" }
    var tint: Color { .purple }

    @PublishedPersist(key: "ocr_enabled", defaultValue: true)
    var isEnabled: Bool

    @PublishedPersist(key: "ocr_recognition_languages", defaultValue: ["ja-JP", "en-US", "zh-Hans", "zh-Hant", "ko-KR"])
    var recognitionLanguages: [String]

    @PublishedPersist(key: "ocr_recognition_level", defaultValue: 0)  // 0=accurate, 1=fast
    var recognitionLevel: Int

    @PublishedPersist(key: "ocr_output_to_source", defaultValue: true)
    var outputToSourceDir: Bool  // true=same dir as source, false=custom dir

    @PublishedPersist(key: "ocr_custom_output_dir", defaultValue: "")
    var customOutputDir: String  // path when outputToSourceDir=false

    @PublishedPersist(key: "ocr_image_name_template", defaultValue: "{name}.{ext}-ocr.pdf")
    var imageNameTemplate: String  // template for image files

    @PublishedPersist(key: "ocr_pdf_name_template", defaultValue: "{name}.{ext}-ocr.pdf")
    var pdfNameTemplate: String  // template for PDF files

    @Published var isProcessing = false
    @Published var isHovered = false

    /// Convert integer recognition level to Vision framework enum.
    /// 0 = .accurate, 1 = .fast
    private var visionRecognitionLevel: VNRequestTextRecognitionLevel {
        recognitionLevel == 0 ? .accurate : .fast
    }

    func onDropTargeted(hover: Bool) {
        isHovered = hover
    }

    func onDrop(providers: [NSItemProvider], itemIDs: [TrayDrop.DropItem.ID]) {
        // 外部DnD (Finderからの直接ドロップ) を処理
        if itemIDs.isEmpty, !providers.isEmpty {
            handleExternalDrop(providers: providers)
            return
        }

        guard !itemIDs.isEmpty else { return }
        isProcessing = true

        Task {
            defer {
                Task { @MainActor in
                    self.isProcessing = false
                }
            }

            for id in itemIDs {
                guard let item = TrayDrop.shared.items.first(where: { $0.id == id }),
                      !item.isText, !item.isWebURL
                else { continue }
                let ext = item.sourceURL.pathExtension.lowercased()
                let isPDF = ext == "pdf"
                let isImage = ["png", "jpg", "jpeg", "tiff", "tif", "heic", "heif", "webp", "bmp"].contains(ext)
                guard isPDF || isImage else { continue }

                guard let sourceURL = item.accessSource({ $0 }) else { continue }

                let defaultOutput = resolveOutputURL(for: sourceURL)

                // Check for name collision on the main actor (NSAlert must be called on main thread)
                let finalURL = await MainActor.run { [defaultOutput] in
                    self.resolveCollision(for: defaultOutput)
                }
                guard let finalURL else { continue }

                do {
                    let pages: [RecognizedPage]
                    let generatedURL: URL
                    if ext == "pdf" {
                        pages = try await PDFOCREngine.recognize(pdf: sourceURL, recognitionLanguages: recognitionLanguages, recognitionLevel: visionRecognitionLevel, progress: { _ in })
                        generatedURL = try PDFSearchableBuilder.buildSearchablePDF(source: sourceURL, pages: pages)
                    } else {
                        guard let imageSource = CGImageSourceCreateWithURL(sourceURL as CFURL, nil),
                              let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil)
                        else { continue }
                        pages = try await PDFOCREngine.recognize(image: cgImage, recognitionLanguages: recognitionLanguages, recognitionLevel: visionRecognitionLevel, progress: { _ in })
                        generatedURL = try PDFSearchableBuilder.buildSearchablePDF(image: cgImage, lines: pages[0].lines, source: sourceURL)
                    }

                    // If the generated file is at a different path (Keep Both scenario), move it
                    if generatedURL != finalURL {
                        // Remove any existing file at the destination first
                        if FileManager.default.fileExists(atPath: finalURL.path) {
                            try? FileManager.default.removeItem(at: finalURL)
                        }
                        try FileManager.default.moveItem(at: generatedURL, to: finalURL)
                    }

                    // DropItem作成はオフメインで行う (DropItemイニシャライザに assert(!Thread.isMainThread) あり)
                    let dropItem = try? TrayDrop.DropItem(url: finalURL)

                    // トレイ追加のみメインスレッドで行う
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
    }

    func contextMenuItems(for item: TrayDrop.DropItem) -> [PluginMenuItem] {
        // Only show for PDF and image items; skip text and web URL items
        let ext = item.sourceURL.pathExtension.lowercased()
        let isPDF = ext == "pdf"
        let isImage = ["png", "jpg", "jpeg", "tiff", "tif", "heic", "heif", "webp", "bmp"].contains(ext)
        guard !item.isText, !item.isWebURL,
              isPDF || isImage
        else { return [] }

        return [
            PluginMenuItem(
                title: NSLocalizedString("Create Searchable PDF", comment: ""),
                icon: "text.viewfinder",
                action: { [weak self] in
                    self?.onDrop(providers: [], itemIDs: [item.id])
                }
            ),
            PluginMenuItem(
                title: NSLocalizedString("Copy OCR Text", comment: ""),
                icon: "doc.text.magnifyingglass",
                action: { [weak self] in
                    guard let self else { return }
                    Task { @MainActor in
                        self.isProcessing = true
                        defer { self.isProcessing = false }
                        guard let url = item.accessSource({ $0 }) else { return }
                        do {
                            let pages: [RecognizedPage]
                            if ext == "pdf" {
                                pages = try await PDFOCREngine.recognize(pdf: url, recognitionLanguages: self.recognitionLanguages, recognitionLevel: self.visionRecognitionLevel, progress: { _ in })
                            } else {
                                guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil),
                                      let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil)
                                else { return }
                                pages = try await PDFOCREngine.recognize(image: cgImage, recognitionLanguages: self.recognitionLanguages, recognitionLevel: self.visionRecognitionLevel, progress: { _ in })
                            }
                            let text = pages.map { page in
                                page.lines.map(\.text).joined(separator: "\n")
                            }.joined(separator: "\n\n")
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(text, forType: .string)
                        } catch {
                            NSAlert.popError(error)
                        }
                    }
                }
            )
        ]
    }

    func dropTargetLabel(count: Int) -> String {
        let format = NSLocalizedString("Create %d Searchable PDFs", comment: "")
        return String.localizedStringWithFormat(format, count)
    }

    // MARK: - External Drop (Finderからの直接ドロップ)

    /// 外部DnD（Finderからの直接ドロップ）のハンドリング。
    /// itemIDs が空で providers が存在する場合に呼ばれる。
    private func handleExternalDrop(providers: [NSItemProvider]) {
        isProcessing = true
        Task {
            defer {
                Task { @MainActor in
                    self.isProcessing = false
                }
            }

            // providers から URL を解決（resolveAnyURL は同期・semaphore 使用のためバックグラウンドで呼ぶ）
            let urls = resolveURLs(from: providers)

            for sourceURL in urls {
                let ext = sourceURL.pathExtension.lowercased()
                let isPDF = ext == "pdf"
                let isImage = ["png", "jpg", "jpeg", "tiff", "tif", "heic", "heif", "webp", "bmp"].contains(ext)
                guard isPDF || isImage else { continue }
                let defaultOutput = resolveOutputURL(for: sourceURL)

                let finalURL = await MainActor.run { [defaultOutput] in
                    self.resolveCollision(for: defaultOutput)
                }
                guard let finalURL else { continue }

                do {
                    let pages: [RecognizedPage]
                    let generatedURL: URL
                    if ext == "pdf" {
                        pages = try await PDFOCREngine.recognize(pdf: sourceURL, recognitionLanguages: recognitionLanguages, recognitionLevel: visionRecognitionLevel, progress: { _ in })
                        generatedURL = try PDFSearchableBuilder.buildSearchablePDF(source: sourceURL, pages: pages)
                    } else {
                        guard let imageSource = CGImageSourceCreateWithURL(sourceURL as CFURL, nil),
                              let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil)
                        else { continue }
                        pages = try await PDFOCREngine.recognize(image: cgImage, recognitionLanguages: recognitionLanguages, recognitionLevel: visionRecognitionLevel, progress: { _ in })
                        generatedURL = try PDFSearchableBuilder.buildSearchablePDF(image: cgImage, lines: pages[0].lines, source: sourceURL)
                    }

                    if generatedURL != finalURL {
                        if FileManager.default.fileExists(atPath: finalURL.path) {
                            try? FileManager.default.removeItem(at: finalURL)
                        }
                        try FileManager.default.moveItem(at: generatedURL, to: finalURL)
                    }

                    // 外部DnDの場合はトレイに追加しない（元ファイルはFinderにある）
                } catch {
                    await MainActor.run {
                        NSAlert.popError(error)
                    }
                }
            }
        }
    }

    /// NSItemProvider の配列から同期的に URL を解決する。
    /// - Note: 内部で `resolveAnyURL()` を使用。semaphore を利用した同期メソッドのため
    ///         バックグラウンドスレッドから呼び出すこと。
    private func resolveURLs(from providers: [NSItemProvider]) -> [URL] {
        providers.compactMap { $0.resolveAnyURL() }
    }

    // MARK: - Helpers

    /// Resolve the output URL using current settings.
    func resolveOutputURL(for sourceURL: URL) -> URL {
        let dir: URL
        if outputToSourceDir {
            dir = sourceURL.deletingLastPathComponent()
        } else {
            let custom = (customOutputDir as NSString).expandingTildeInPath
            dir = URL(fileURLWithPath: custom)
        }

        let ext = sourceURL.pathExtension.lowercased()
        let isPDF = ext == "pdf"
        let template = isPDF ? pdfNameTemplate : imageNameTemplate
        let name = sourceURL.deletingPathExtension().lastPathComponent

        var outputName = template
            .replacingOccurrences(of: "{name}", with: name)
            .replacingOccurrences(of: "{ext}", with: ext)

        // Ensure .pdf extension
        if !outputName.hasSuffix(".pdf") {
            outputName += ".pdf"
        }

        return dir.appendingPathComponent(outputName)
    }

    /// Checks for file name collision at `outputURL` and presents an NSAlert dialog.
    /// - Returns: The resolved URL to use, or `nil` if the operation was cancelled.
    @MainActor
    private func resolveCollision(for outputURL: URL) -> URL? {
        let fm = FileManager.default
        guard fm.fileExists(atPath: outputURL.path) else { return outputURL }

        let alert = NSAlert()
        alert.messageText = NSLocalizedString("File Already Exists", comment: "")
        alert.informativeText = String.localizedStringWithFormat(
            NSLocalizedString("%@ already exists. What would you like to do?", comment: ""),
            outputURL.lastPathComponent
        )
        alert.addButton(withTitle: NSLocalizedString("Replace", comment: ""))
        alert.addButton(withTitle: NSLocalizedString("Keep Both", comment: ""))
        alert.addButton(withTitle: NSLocalizedString("Cancel", comment: ""))

        let response = alert.runModal()
        switch response {
        case .alertFirstButtonReturn:
            // Replace – remove existing file, use the original name
            try? fm.removeItem(at: outputURL)
            return outputURL
        case .alertSecondButtonReturn:
            // Keep Both – find the next available numbered name
            let dir = outputURL.deletingLastPathComponent()
            let baseName = outputURL.deletingPathExtension().lastPathComponent
            let ext = outputURL.pathExtension
            var counter = 2
            while true {
                let newURL = dir.appendingPathComponent("\(baseName).\(counter).\(ext)")
                if !fm.fileExists(atPath: newURL.path) {
                    return newURL
                }
                counter += 1
            }
        case .alertThirdButtonReturn:
            // Cancel – skip this file entirely
            return nil
        default:
            return nil
        }
    }
}
