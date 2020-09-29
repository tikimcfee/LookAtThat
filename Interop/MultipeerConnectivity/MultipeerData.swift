import MultipeerConnectivity
import Foundation

class PeerConnection: Equatable, Hashable {
    var targetPeerId: MCPeerID
    var state: PeerConnectionState
    init(targetPeerId: MCPeerID,
         state: PeerConnectionState) {
        self.targetPeerId = targetPeerId
        self.state = state
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(targetPeerId)
    }

    public static func == (_ left: PeerConnection, _ right: PeerConnection) -> Bool {
        return left.targetPeerId == right.targetPeerId
            && left.state == right.state
    }
}

enum PeerConnectionState: String, CustomStringConvertible {
    case invited
    case connecting
    case connected
    case notConnected
    case lost
    case unknownState

    var description: String { return rawValue }

    static func forState(_ state: MCSessionState) -> PeerConnectionState {
        switch state {
        case .connecting:
            return .connecting
        case .connected:
            return .connected
        case .notConnected:
            return .notConnected
        @unknown default:
            return .unknownState
        }
    }
}

enum ConnectionData: CustomStringConvertible {
    static let messageName = "message::"
    static let errorName = "error::"
    static let sheetName = "sheet::"
    static let encoding = String.Encoding.utf8

    case message(String)
    case sheet(CodeSheet)
    case error

    var name: String {
        switch self {
        case .message:
            return Self.messageName
        case .error:
            return Self.errorName
        case .sheet:
            return Self.sheetName
        }
    }

    var description: String {
        switch self {
        case let .message(message):
            return name.appending(message)
        case .error:
            return name
        case .sheet:
            return name
        }
    }

    var toData: Data {
        switch self {
        case .message, .error:
            return description.data(using: Self.encoding) ?? {
                print("!! Failed to encode !!", description)
                return Data()
            }()
        case .sheet(let sheet):
            let encoder = JSONEncoder()
            return try! encoder.encode(sheet.wireSheet)
        }
    }

    static func fromData(_ data: Data) -> ConnectionData {
        if let maybeSheet = try? JSONDecoder().decode(WireSheet.self, from: data) {
            let rootSheet = maybeSheet.makeCodeSheet()
            return ConnectionData.sheet(rootSheet)
        } else {
            guard let messageData = String(data: data, encoding: Self.encoding) else {
                return .error
            }
            switch messageData {
            case ConnectionData.error.name:
                return .error
            default:
                if messageData.starts(with: messageName) {
                    let parsedMessage = messageData.replacingOccurrences(of: messageName, with: "")
                    return .message(parsedMessage)
                } else {
                    return .error
                }
            }
        }
    }
}

final class SheetDataTransformer {
    let jsonEncoder = JSONEncoder()
    let jsonDecoder = JSONDecoder()
    let compressionFormat = NSData.CompressionAlgorithm.lzma

    init() {
        jsonEncoder.outputFormatting = .withoutEscapingSlashes
    }

    func data(from sheet: CodeSheet) -> Data? {
        print("Converting sheet \(sheet.id) for transfer")
        let wireSheet = sheet.wireSheet
        print("\(sheet.id) converted; encoding.")

        guard let encoding =
                try? jsonEncoder.encode(wireSheet)
        else {
            print("Failed to encode sheet")
            return nil
        }

        print("Sheet starting is size \(encoding.kb)kb. Compressing...")

        guard let compressed =
                try? (encoding as NSData).compressed(using: compressionFormat)
        else {
            print("Failed to compress sheet")
            return nil
        }
        print("Sheet compressed to \(compressed.kb)kb.")

        return compressed as Data?
    }

    func sheet(from data: Data) -> CodeSheet? {
        print("Converting data to sheet (\(data.kb)kb); decompressing..")

        guard let decompressed =
                try? (data as NSData).decompressed(using: compressionFormat)
        else {
            print("Failed to decompress data")
            return nil
        }

        print("Data decompressed to (\(decompressed.kb)kb); decoding..")

        guard let wireSheet =
                try? jsonDecoder.decode(WireSheet.self, from: decompressed as Data)
        else {
            print("Failed to decode a WireSheet")
            return nil
        }

        print("WireSheet decoded (\(wireSheet.id)); finalizing into CodeSheet")
        let finalSheet = wireSheet.makeCodeSheet()
        print("CodeSheet recreated! (\(finalSheet.id)")

        return finalSheet
    }
}

extension Data {
    var kb: Float { return Float(count) / 1024 }
    var mb: Float { return kb / 1024 }
}

extension NSData {
    var kb: Float { return Float(count) / 1024 }
    var mb: Float { return kb / 1024 }
}
