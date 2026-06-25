//
//  Ext+PDFPage.swift
//  NotchCloset
//

import PDFKit
import CoreGraphics

// MARK: - PDFPage Rendering

/// Errors that can occur during PDF page rendering.
public enum PDFPageRenderError: Error, Equatable {
    /// The bitmap context could not be created.
    case contextCreationFailed
    /// The CGImage could not be extracted from the rendered context.
    case imageExtractionFailed
}

extension PDFPage {
    /// Render this page to a CGImage at the given DPI scale.
    ///
    /// - Parameters:
    ///   - scale: DPI / 72 (e.g., 150/72 ≈ 2.083).
    ///   - pixelWidth: Width in pixels.
    ///   - pixelHeight: Height in pixels.
    /// - Returns: A rendered CGImage backed by an RGB bitmap context.
    func renderImage(scale: CGFloat, pixelWidth: Int, pixelHeight: Int) throws -> CGImage {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo.byteOrder32Little.rawValue
            | CGImageAlphaInfo.premultipliedFirst.rawValue

        guard let ctx = CGContext(
            data: nil,
            width: pixelWidth,
            height: pixelHeight,
            bitsPerComponent: 8,
            bytesPerRow: pixelWidth * 4,
            space: colorSpace,
            bitmapInfo: bitmapInfo
        ) else {
            throw PDFPageRenderError.contextCreationFailed
        }

        // White background.
        ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
        ctx.fill(CGRect(x: 0, y: 0, width: pixelWidth, height: pixelHeight))

        // Scale to the desired DPI and draw the page.
        ctx.scaleBy(x: scale, y: scale)
        self.draw(with: .mediaBox, to: ctx)

        guard let image = ctx.makeImage() else {
            throw PDFPageRenderError.imageExtractionFailed
        }

        return image
    }
}
