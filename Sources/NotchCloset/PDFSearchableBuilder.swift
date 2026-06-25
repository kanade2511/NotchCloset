//
//  PDFSearchableBuilder.swift
//  NotchCloset
//

import PDFKit
import CoreGraphics
import AppKit
import UniformTypeIdentifiers

// MARK: - Searchable PDF Builder

/// Builds a searchable PDF (`.ocr.pdf`) by overlaying invisible recognised
/// text on top of rendered page images.
public enum PDFSearchableBuilder {
    public enum BuilderError: Error, Equatable {
        case sourceMissing
        case sourceUnreadable
        case destinationUnwritable
        case pageRenderFailed
        case pdfCreationFailed
    }

    private static let dpi: CGFloat = 150
    private static let pointsPerInch: CGFloat = 72

    /// Build a searchable PDF next to the source file.
    ///
    /// The output file is written to the same directory as `source` with the
    /// stem `<original>.ocr.pdf`. Collision handling is left to the caller.
    ///
    /// - Parameters:
    ///   - source: Source PDF URL (used for directory and base name).
    ///   - pages: Recognised pages from ``PDFOCREngine``.
    /// - Returns: URL of the created `.ocr.pdf` file.
    public static func buildSearchablePDF(
        source url: URL,
        pages: [RecognizedPage]
    ) throws -> URL {
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw BuilderError.sourceMissing
        }

        guard let document = PDFDocument(url: url), document.pageCount > 0 else {
            throw BuilderError.sourceUnreadable
        }

        let outputURL = url
            .deletingPathExtension()
            .appendingPathExtension("ocr.pdf")

        guard let consumer = CGDataConsumer(url: outputURL as CFURL) else {
            throw BuilderError.destinationUnwritable
        }

        // Initial media-box is overridden per page via beginPDFPage.
        var mediaBox = CGRect.zero
        guard let pdfContext = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else {
            throw BuilderError.pdfCreationFailed
        }

        let totalPages = document.pageCount
        let scale = dpi / pointsPerInch

        for pageIndex in 0 ..< min(totalPages, pages.count) {
            guard let page = document.page(at: pageIndex) else { continue }
            let recognised = pages[pageIndex]

            let pageBounds = page.bounds(for: .mediaBox)
            let pixelWidth = Int(ceil(pageBounds.width * scale))
            let pixelHeight = Int(ceil(pageBounds.height * scale))
            guard pixelWidth > 0, pixelHeight > 0 else { continue }

            // Render the original page at 150 DPI.
            let cgImage = try page.renderImage(scale: scale,
                                               pixelWidth: pixelWidth,
                                               pixelHeight: pixelHeight)

            // Re-encode as JPEG so CGPDFContext can embed it efficiently.
            let jpegData = try encodeJPEG(cgImage)
            guard let jpegImage = decodeJPEG(jpegData) else {
                throw BuilderError.pageRenderFailed
            }

            // Begin a new PDF page with the original media box.
            let pageInfo: CFDictionary = [
                kCGPDFContextMediaBox: NSValue(rect: pageBounds)
            ] as CFDictionary
            pdfContext.beginPDFPage(pageInfo)

            // Draw the rendered (JPEG) image.
            pdfContext.draw(jpegImage, in: pageBounds)

            // Overlay invisible text so the PDF is searchable.
            drawInvisibleText(in: pdfContext, lines: recognised.lines,
                              pageBounds: pageBounds)

            pdfContext.endPDFPage()
        }

        pdfContext.closePDF()

        guard FileManager.default.fileExists(atPath: outputURL.path) else {
            throw BuilderError.pdfCreationFailed
        }

        return outputURL
    }
}

// MARK: - JPEG Round-Trip

extension PDFSearchableBuilder {
    /// Compress a CGImage to JPEG data (quality 0.9).
    private static func encodeJPEG(_ image: CGImage) throws -> Data {
        let mutableData = NSMutableData()
        let type = UTType.jpeg.identifier as CFString
        guard let destination = CGImageDestinationCreateWithData(mutableData, type, 1, nil)
        else {
            throw BuilderError.pageRenderFailed
        }

        let options: CFDictionary = [
            kCGImageDestinationLossyCompressionQuality: 0.9
        ] as CFDictionary

        CGImageDestinationAddImage(destination, image, options)
        guard CGImageDestinationFinalize(destination) else {
            throw BuilderError.pageRenderFailed
        }

        return mutableData as Data
    }

    /// Decode a CGImage from JPEG data.
    private static func decodeJPEG(_ data: Data) -> CGImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        return CGImageSourceCreateImageAtIndex(source, 0, nil)
    }
}

// MARK: - Invisible Text Overlay

extension PDFSearchableBuilder {
    /// Draw each recognised line as invisible text using Core Text.
    ///
    /// The coordinate system in a CGPDFContext is bottom-left origin, matching
    /// Vision's normalised bounding-box convention, so no vertical flip is
    /// needed.
    private static func drawInvisibleText(
        in context: CGContext,
        lines: [RecognizedLine],
        pageBounds: CGRect
    ) {
        context.saveGState()
        context.setTextDrawingMode(.invisible)

        for line in lines {
            let bbox = line.boundingBox

            // Convert Vision normalised coordinates → PDF points.
            let x = bbox.origin.x * pageBounds.width
            let y = bbox.origin.y * pageBounds.height
            let h = bbox.size.height * pageBounds.height

            // Font size proportional to the text region height.
            let fontSize = max(h * 0.85, 4.0)

            guard let font = CTFontCreateWithName(
                "Helvetica" as CFString, fontSize, nil
            ) as CTFont? else { continue }

            let attributes: [CFString: Any] = [
                kCTFontAttributeName: font,
                kCTForegroundColorAttributeName: NSColor.black.cgColor,
            ]

            guard let attrString = CFAttributedStringCreate(
                nil, line.text as CFString, attributes as CFDictionary
            ) else { continue }

            let ctLine = CTLineCreateWithAttributedString(attrString)

            // Position the text baseline at the bottom of the bounding box.
            context.textPosition = CGPoint(x: x, y: y)
            CTLineDraw(ctLine, context)
        }

        context.restoreGState()
    }
}
