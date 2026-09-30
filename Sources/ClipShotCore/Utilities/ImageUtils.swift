import Foundation
import AppKit
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

/// High-performance image utilities for format detection, dimension extraction, thumbnail generation, and encoding.
public enum ImageUtils {

    /// Supported image extensions.
    public static let supportedExtensions: Set<String> = ["png", "jpg", "jpeg", "tiff", "tif", "heic", "heif", "webp"]

    /// Checks if the given URL corresponds to a supported image file type.
    public static func isImageFile(at url: URL) -> Bool {
        let ext = url.pathExtension.lowercased()
        if supportedExtensions.contains(ext) { return true }

        guard let uti = UTType(filenameExtension: ext) else { return false }
        return uti.conforms(to: .image)
    }

    /// Extracts pixel dimensions and file size using ImageIO without decoding full bitmap into RAM.
    /// - Parameter url: File URL of the candidate image.
    /// - Returns: Tuple of width in pixels, height in pixels, and file size in bytes, or nil if unreadable.
    public static func getImageMetadata(at url: URL) -> (width: Int, height: Int, fileSize: Int64)? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
        guard let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any] else { return nil }

        let width = properties[kCGImagePropertyPixelWidth] as? Int ?? 0
        let height = properties[kCGImagePropertyPixelHeight] as? Int ?? 0

        var fileSize: Int64 = 0
        if let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
           let size = attrs[.size] as? Int64 {
            fileSize = size
        }

        return (width, height, fileSize)
    }

    /// Checks whether an image at a URL is valid and readable by ImageIO.
    /// - Parameter url: File URL to test.
    /// - Returns: True if file exists and ImageIO reports statusComplete with at least 1 image frame.
    public static func isValidImage(at url: URL) -> Bool {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return false }
        let count = CGImageSourceGetCount(source)
        guard count > 0 else { return false }
        let status = CGImageSourceGetStatus(source)
        return status == .statusComplete
    }

    /// Generates a downscaled thumbnail NSImage directly via ImageIO hardware acceleration.
    ///
    /// Key ImageIO options utilized:
    /// - `kCGImageSourceCreateThumbnailFromImageAlways`: Guarantees generation even if embedded thumbnail is absent.
    /// - `kCGImageSourceShouldCacheImmediately`: Decodes directly into graphics memory to prevent UI hitching on draw.
    /// - `kCGImageSourceCreateThumbnailWithTransform`: Respects EXIF camera orientation tags automatically.
    /// - `kCGImageSourceThumbnailMaxPixelSize`: Constrains the longest dimension while preserving aspect ratio.
    ///
    /// - Parameters:
    ///   - url: File system URL of the source image.
    ///   - maxDimension: Maximum allowable width or height in physical pixels (defaults to 300).
    /// - Returns: Renderable `NSImage` sized to thumbnail dimensions, or `nil` if decoding failed.
    public static func generateThumbnail(from url: URL, maxDimension: CGFloat = 300) -> NSImage? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }

        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxDimension
        ]

        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            return nil
        }

        return NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
    }

    /// Converts NSImage to PNG Data.
    public static func pngData(from image: NSImage) -> Data? {
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData) else {
            return nil
        }
        return bitmap.representation(using: .png, properties: [:])
    }

    /// Converts CGImage to PNG Data.
    public static func pngData(from cgImage: CGImage) -> Data? {
        let bitmap = NSBitmapImageRep(cgImage: cgImage)
        return bitmap.representation(using: .png, properties: [:])
    }

    /// Converts NSImage to TIFF Data.
    public static func tiffData(from image: NSImage) -> Data? {
        return image.tiffRepresentation
    }

    /// Loads an NSImage from URL safely.
    public static func loadImage(at url: URL) -> NSImage? {
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        return NSImage(contentsOf: url)
    }

    /// Saves an NSImage as PNG to the specified destination URL.
    public static func savePNG(image: NSImage, to destinationURL: URL) throws {
        guard let data = pngData(from: image) else {
            throw NSError(domain: "ClipShot", code: 101, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to PNG"])
        }
        try data.write(to: destinationURL, options: .atomic)
    }

    /// Applies a Gaussian blur privacy redaction filter to a specific rectangular region of a CGImage.
    ///
    /// The redaction pipeline:
    /// 1. Converts input `CGImage` to `CIImage` coordinate space.
    /// 2. Applies `CIGaussianBlur` with a 15.0 pt blur radius.
    /// 3. Renders the blurred output via `CIContext`.
    /// 4. Composites the blurred region atop the crisp original using CoreGraphics clipping context (`clip(to: rect)`).
    ///
    /// - Parameters:
    ///   - image: Source bitmap to redact.
    ///   - rect: Pixel-aligned rectangular bounding box to blur.
    /// - Returns: Newly allocated `CGImage` containing the selectively redacted image, or `nil` on failure.
    public static func blurRegion(in image: CGImage, rect: CGRect) -> CGImage? {
        let ciImage = CIImage(cgImage: image)
        guard let filter = CIFilter(name: "CIGaussianBlur") else { return nil }
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        filter.setValue(15.0, forKey: kCIInputRadiusKey)

        guard let blurred = filter.outputImage else { return nil }

        // Composite blurred region over original
        let context = CIContext(options: nil)
        guard let blurredCG = context.createCGImage(blurred, from: ciImage.extent) else { return nil }

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let gContext = CGContext(
            data: nil,
            width: image.width,
            height: image.height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        let fullRect = CGRect(x: 0, y: 0, width: image.width, height: image.height)
        gContext.draw(image, in: fullRect)

        gContext.saveGState()
        gContext.clip(to: rect)
        gContext.draw(blurredCG, in: fullRect)
        gContext.restoreGState()

        return gContext.makeImage()
    }
}
