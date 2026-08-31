import Foundation
import AppKit
import Vision

/// Offline Optical Character Recognition service using Apple's Vision framework.
public final class OCRService: @unchecked Sendable {
    public static let shared = OCRService()

    public init() {}

    /// Performs text recognition on a CGImage asynchronously.
    public func recognizeText(from cgImage: CGImage) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: "")
                    return
                }

                let recognizedLines = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }

                let fullText = recognizedLines.joined(separator: "\n")
                continuation.resume(returning: fullText)
            }

            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    /// Performs text recognition on an NSImage.
    public func recognizeText(from image: NSImage) async throws -> String {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw NSError(domain: "ClipShot", code: 201, userInfo: [NSLocalizedDescriptionKey: "Failed to obtain CGImage from NSImage"])
        }
        return try await recognizeText(from: cgImage)
    }

    /// Performs text recognition on an image file URL.
    public func recognizeText(from url: URL) async throws -> String {
        guard let image = ImageUtils.loadImage(at: url) else {
            throw NSError(domain: "ClipShot", code: 202, userInfo: [NSLocalizedDescriptionKey: "Failed to load image file"])
        }
        return try await recognizeText(from: image)
    }

    /// Detects QR codes and barcodes locally using Vision.
    public func detectBarcodes(from image: NSImage) async throws -> [String] {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return []
        }

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNDetectBarcodesRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let results = request.results as? [VNBarcodeObservation] else {
                    continuation.resume(returning: [])
                    return
                }

                let payloads = results.compactMap { $0.payloadStringValue }
                continuation.resume(returning: payloads)
            }

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    /// Parses text for URLs, email addresses, phone numbers, and dates.
    public func detectSmartData(in text: String) -> (urls: [URL], emails: [String], phoneNumbers: [String]) {
        var urls: [URL] = []
        var emails: [String] = []
        var phoneNumbers: [String] = []

        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue | NSTextCheckingResult.CheckingType.phoneNumber.rawValue) else {
            return (urls, emails, phoneNumbers)
        }

        let matches = detector.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))
        for match in matches {
            if match.resultType == .link, let url = match.url {
                if url.scheme == "mailto" {
                    emails.append(url.absoluteString.replacingOccurrences(of: "mailto:", with: ""))
                } else {
                    urls.append(url)
                }
            } else if match.resultType == .phoneNumber, let phone = match.phoneNumber {
                phoneNumbers.append(phone)
            }
        }

        return (urls, emails, phoneNumbers)
    }

    /// Extracts text and copies directly to clipboard, returning the text.
    @discardableResult
    public func ocrAndCopy(from image: NSImage) async throws -> String {
        let text = try await recognizeText(from: image)
        await MainActor.run {
            ClipboardManager.shared.copyText(text)
            SoundManager.shared.playCopySound()
        }
        return text
    }

    /// Extracts text from URL and copies directly to clipboard.
    @discardableResult
    public func ocrAndCopy(from url: URL) async throws -> String {
        let text = try await recognizeText(from: url)
        await MainActor.run {
            ClipboardManager.shared.copyText(text)
            SoundManager.shared.playCopySound()
        }
        return text
    }
}
