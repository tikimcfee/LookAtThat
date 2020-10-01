import Foundation
import Brotli

final class SheetDataTransformer {
    enum Mode { case brotli, standard }
    private let jsonEncoder = JSONEncoder()
    private let jsonDecoder = JSONDecoder()
    private let compressionFormat = NSData.CompressionAlgorithm.lzma
    var mode: Mode = .standard

    init() {
        jsonEncoder.outputFormatting = .withoutEscapingSlashes
    }

    func data(from sheet: CodeSheet) -> Data? {
        print("Converting sheet \(sheet.id) for transfer")
        let wireSheet = sheet.wireSheet

        print("\(sheet.id) converted; encoding.")
        guard let encoding = encode(wireSheet) else { return nil }

        print("Sheet starting is size \(encoding.kb)kb. Compressing...")
        guard let compressed = compress(encoding) else { return nil }

        print("Sheet compressed to \(compressed.kb)kb.")

        return compressed
    }

    func sheet(from data: Data) -> CodeSheet? {
        print("Converting data to sheet (\(data.kb)kb); decompressing..")
        guard let decompressed = decompress(data) else { return nil }

        print("Data decompressed to (\(decompressed.kb)kb); decoding..")
        guard let wireSheet = decode(decompressed) else { return nil }

        print("WireSheet decoded (\(wireSheet.id)); finalizing into CodeSheet")
        let finalSheet = wireSheet.makeCodeSheet()
        print("CodeSheet recreated! (\(finalSheet.id)")

        return finalSheet
    }

    private func encode(_ sheet: WireSheet) -> Data? {
        do {
            return try jsonEncoder.encode(sheet)
        } catch {
            print("Failed to encode \(sheet.id)", error)
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

    private func compress(_ data: Data) -> Data? {
        switch mode {
        case .brotli:
            return compressBrotli(data)
        case .standard:
            return compressStandard(data)
        }
    }

    private func decompress(_ data: Data) -> Data? {
        switch mode {
        case .brotli:
            return decompressBrotli(data)
        case .standard:
            return decompressStandard(data)
        }
    }
}

// Brotli compression
extension SheetDataTransformer {
    private func compressBrotli(_ data: Data) -> Data? {
        return data.nsData.brotliCompressed()
    }

    private func decompressBrotli(_ data: Data) -> Data? {
        return data.nsData.brotliDecompressed()
    }
}

// OS provided compression
extension SheetDataTransformer {
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
