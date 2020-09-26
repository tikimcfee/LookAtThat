import MultipeerConnectivity
import Foundation

class PeerConnection {
    var targetPeerId: MCPeerID
    var state: PeerConnectionState
    var session: MCSession
    init(targetPeerId: MCPeerID,
         state: PeerConnectionState,
         session: MCSession) {
        self.targetPeerId = targetPeerId
        self.state = state
        self.session = session
    }
}

enum PeerConnectionState: String, CustomStringConvertible {
    case invited
    case connecting
    case connected
    case notConnected
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

    var toData: Data? {
        return description.data(using: Self.encoding)!
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
