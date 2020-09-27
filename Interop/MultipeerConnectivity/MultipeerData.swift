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
    static let encoding = String.Encoding.utf8

    case message(String)
    case error

    var name: String {
        switch self {
        case .message:
            return Self.messageName
        case .error:
            return Self.errorName
        }
    }

    var description: String {
        switch self {
        case let .message(message):
            return name.appending(message)
        case .error:
            return name
        }
    }

    var toData: Data {
        return description.data(using: Self.encoding) ?? {
            print("!! Failed to encode !!", description)
            return Data()
        }()
    }

    static func fromData(_ data: Data) -> ConnectionData {
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
