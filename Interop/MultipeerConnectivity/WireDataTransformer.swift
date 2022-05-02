import Foundation
import Brotli

final class WireDataTransformer {
    enum DataError: Error { case decompression, compression, decodeString }
    enum Mode: CaseIterable { case brotli, standard }
    private let jsonEncoder = JSONEncoder()
    private let jsonDecoder = JSONDecoder()
    private let compressionFormat = NSData.CompressionAlgorithm.lzma
    var mode: Mode = .standard

    init() {
        jsonEncoder.outputFormatting = .withoutEscapingSlashes
    }
}

// MARK: - CodeSheets
extension WireDataTransformer {
    func encodedString(_ string: String) -> Data? {
        guard let data = string.data(using: .utf8) else { return nil }
        return compress(data)
    }
    
    func decodedString(_ data: Data) throws -> String {
        guard let data = decompress(data) else {
            print("Failed to decompress string")
            throw WireDataTransformer.DataError.decompression
        }
        guard let result = String(data: data, encoding: .utf8) else {
            print("Failed to decode .utf8 string")
            throw WireDataTransformer.DataError.decodeString
        }
        return result
    }
    
    func encodeAttributedString(_ attributed: NSMutableAttributedString) throws -> Data? {
        let range = attributed.string.fullNSRange
        let attributes: [NSAttributedString.DocumentAttributeKey: Any] = [
            .documentType : NSAttributedString.DocumentType.rtf
        ]
        let rtfData = try attributed.data(from: range, documentAttributes: attributes)
        return compress(rtfData)
    }
    
    func decodeAttributedString(_ data: Data) throws -> (NSAttributedString, NSDictionary) {
        // Apparently the RTF reader automatically decodes some default paragraph and font styles which.. we don't want.
        // So we just remove then on decode and pass back. We need to retain colorization, but the rest is not needed.
        // Hopefully different iOS versions don't change this too much.
        guard let data = decompress(data) else {
            print("Failed to decompress attributed data")
            throw WireDataTransformer.DataError.decompression
        }
        
        var dict: NSDictionary? = NSDictionary()
        #if os(iOS)
        let mutable = try NSMutableAttributedString(data: data, options: [:], documentAttributes: &dict)
        #elseif os(macOS)
        let mutable = NSMutableAttributedString(rtf: data, documentAttributes: &dict) ?? NSMutableAttributedString()
        #endif
        
        mutable.removeAttribute(.paragraphStyle, range: mutable.string.fullNSRange)
        mutable.removeAttribute(.font, range: mutable.string.fullNSRange)
        return (mutable, dict!)
    }

    
    func data(from source: WireCode) -> Data? {
        guard let data = try? jsonEncoder.encode(source) else { return nil }
        return compress(data)
    }

    func source(from source: Data) -> WireCode? {
        guard let decompressed = decompress(source) else { return nil }
        return try? jsonDecoder.decode(WireCode.self, from: decompressed)
    }
}

// MARK: - Encoding, Decoding
extension WireDataTransformer {
    private func encode<T: Codable & Identifiable>(_ codable: T) -> Data? {
        do {
            return try jsonEncoder.encode(codable)
        } catch {
            print("Failed to encode \(codable.id)", error)
            return nil
        }
    }

    private func decode(_ data: Data) -> WireSheet? {
        do {
            return try jsonDecoder.decode(WireSheet.self, from: data)
        } catch {
            print("Failed to decode data (\(data.count) bytes)", error)
            return nil
        }
    }
}

// MARK: Compression
extension WireDataTransformer {
    func compress(_ data: Data) -> Data? {
        switch mode {
        case .brotli:
            return compressBrotli(data)
        case .standard:
            return compressStandard(data)
        }
    }

    func decompress(_ data: Data) -> Data? {
        switch mode {
        case .brotli:
            return decompressBrotli(data)
        case .standard:
            return decompressStandard(data)
        }
    }
}

// Brotli compression
extension WireDataTransformer {
    private func compressBrotli(_ data: Data) -> Data? {
        return data.nsData.brotliCompressed()
    }

    private func decompressBrotli(_ data: Data) -> Data? {
        return data.nsData.brotliDecompressed()
    }
}

// OS provided compression
extension WireDataTransformer {
    private func compressStandard(_ data: Data) -> Data? {
        do {
            return try data.nsData.compressed(using: compressionFormat).swiftData
        } catch {
            print("Failed to compress data (\(data.count) bytes)", error)
            return nil
        }
    }

    private func decompressStandard(_ data: Data) -> Data? {
        do {
            return try data.nsData.decompressed(using: compressionFormat).swiftData
        } catch {
            print("Failed to compress data (\(data.count) bytes)", error)
            return nil
        }
    }
}

extension Data {
    var kb: Float { return Float(count) / 1024 }
    var mb: Float { return kb / 1024 }
    var nsData: NSData { return self as NSData }
}

extension NSData {
    var kb: Float { return Float(count) / 1024 }
    var mb: Float { return kb / 1024 }
    var swiftData: Data { return self as Data }
}
