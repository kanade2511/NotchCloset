//
//  PDFOCREngine.swift
//  NotchCloset
//

import Vision
import PDFKit
import CoreGraphics

// MARK: - Data Types

/// A single line of recognized text with its normalized bounding box.
/// The bounding box uses Vision normalized coordinates (0–1, bottom-left origin).
public struct RecognizedLine: Equatable, Sendable {
    public let text: String
    public let boundingBox: CGRect

    public init(text: String, boundingBox: CGRect) {
        self.text = text
        self.boundingBox = boundingBox
    }
}

/// A single page's worth of recognized lines.
public struct RecognizedPage: Equatable, Sendable {
    public let lines: [RecognizedLine]

    public init(lines: [RecognizedLine]) {
        self.lines = lines
    }
}

// MARK: - OCR Engine

public enum PDFOCREngine {
    public enum OCRError: Error, Equatable {
        case sourceMissing
        case sourceUnreadable
        case destinationUnwritable
        case recognitionFailed(reason: String)
        case noTextFound
        case cancelled
    }

    private static let dpi: CGFloat = 150
    private static let pointsPerInch: CGFloat = 72

    /// Recognize text on every page of a PDF using Vision.
    /// - Parameters:
    ///   - url: Source PDF URL.
    ///   - recognitionLanguages: Array of language identifiers (e.g., "ja-JP", "en-US").
    ///   - recognitionLevel: Vision text recognition level (.accurate or .fast).
    ///   - progress: Progress callback on an arbitrary thread (0.0 – 1.0).
    /// - Returns: Array of recognized pages.
    public static func recognize(
        pdf url: URL,
        recognitionLanguages: [String] = ["ja-JP", "en-US", "zh-Hans", "zh-Hant", "ko-KR"],
        recognitionLevel: VNRequestTextRecognitionLevel = .accurate,
        progress: @escaping (Double) -> Void
    ) async throws -> [RecognizedPage] {
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw OCRError.sourceMissing
        }

        guard let document = PDFDocument(url: url), document.pageCount > 0 else {
            throw OCRError.sourceUnreadable
        }

        let totalPages = document.pageCount
        var result: [RecognizedPage] = []

        for pageIndex in 0 ..< totalPages {
            guard let page = document.page(at: pageIndex) else { continue }

            let pageBounds = page.bounds(for: .mediaBox)
            let scale = dpi / pointsPerInch
            let pixelWidth = Int(ceil(pageBounds.width * scale))
            let pixelHeight = Int(ceil(pageBounds.height * scale))
            guard pixelWidth > 0, pixelHeight > 0 else { continue }

            // Render the page to a bitmap image.
            let image = try page.renderImage(scale: scale,
                                             pixelWidth: pixelWidth,
                                             pixelHeight: pixelHeight)

            // Run Vision text recognition with the provided parameters.
            let lines = try await recognizeText(in: image,
                                                recognitionLanguages: recognitionLanguages,
                                                recognitionLevel: recognitionLevel)

            result.append(RecognizedPage(lines: lines))

            let p = Double(pageIndex + 1) / Double(totalPages)
            progress(p)
        }

        return result
    }

    // MARK: - Text Recognition

    /// Run VNRecognizeTextRequest on a CGImage and return recognized lines.
    private static func recognizeText(
        in cgImage: CGImage,
        recognitionLanguages: [String],
        recognitionLevel: VNRequestTextRecognitionLevel
    ) async throws -> [RecognizedLine] {
        try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error {
                    continuation.resume(
                        throwing: OCRError.recognitionFailed(reason: error.localizedDescription))
                    return
                }

                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: [])
                    return
                }

                let lines = observations.compactMap { observation -> RecognizedLine? in
                    guard let candidate = observation.topCandidates(1).first else { return nil }
                    return RecognizedLine(
                        text: candidate.string,
                        boundingBox: observation.boundingBox
                    )
                }

                continuation.resume(returning: lines)
            }

            request.recognitionLevel = recognitionLevel
            request.usesLanguageCorrection = true
            request.automaticallyDetectsLanguage = true
            request.recognitionLanguages = recognitionLanguages

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

            do {
                try handler.perform([request])
            } catch {
                continuation.resume(
                    throwing: OCRError.recognitionFailed(reason: error.localizedDescription))
            }
        }
    }
}
