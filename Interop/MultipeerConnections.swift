import Foundation
import MultipeerConnectivity

enum UserKeys: String {
    case mcPeerId
    case applicationServiceType

    private func savedValue() -> String? {
        return UserDefaults.standard.string(forKey: self.rawValue)
    }

    private func save(value: String) -> String {
        UserDefaults.standard.setValue(value, forKey: self.rawValue)
        return value
    }

    func safeValue(using defaultValue: String) -> String {
        return savedValue() ?? {
            return save(value: defaultValue)
        }()
    }
}

class MultipeerCommunicator: NSObject {
    static let myServiceName = "LookAtThat_MacOS_Connections"
    #if os(OSX)
    static let myDefaultName = "LookAtThat_MacOS_".appending(UUID().uuidString)
    #elseif os(iOS)
    static let myDefaultName = "LookAtThat_iOS_".appending(UUID().uuidString)
    #endif

    static var myServiceType: String {
        return UserKeys.applicationServiceType.safeValue(using: Self.myServiceName)
    }

    static var myPeerId: MCPeerID {
        let displayName = UserKeys.mcPeerId.safeValue(using: Self.myDefaultName)
        return MCPeerID(displayName: displayName)
    }

    lazy var discoveryInfo: [String:String] = {
        return [
            "testKey":"testValue"
        ]
    }()

    lazy var serviceBrowser: MCNearbyServiceBrowser = {
        let browser = MCNearbyServiceBrowser(peer: Self.myPeerId, serviceType: Self.myServiceType)
        browser.delegate = self
        return browser
    }()

    lazy var serviceAdvertiser: MCNearbyServiceAdvertiser  = {
        let browser = MCNearbyServiceAdvertiser(peer: Self.myPeerId,
                                                discoveryInfo: discoveryInfo,
                                                serviceType: Self.myServiceType)
        browser.delegate = self
        return browser
    }()

    lazy var globalSession: MCSession = {
        // TODO: encrypt that stuff boyo
        let session = MCSession(peer: Self.myPeerId, securityIdentity: nil, encryptionPreference: .none)
        session.delegate = self
        return session
    }()

    var peerConnections = [MCPeerID: PeerConnection]()

    override init() {
        super.init()
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

extension MultipeerCommunicator: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser,
                    didReceiveInvitationFromPeer peerID: MCPeerID,
                    withContext context: Data?,
                    invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        guard peerConnections[peerID] == nil else {
            print("Received an invitation from an existing connection, may be a reconnection attempt")
            return
        }

        if let data = context {
            let connectionContext = ConnectionData.fromData(data)
            print(connectionContext)
        }

        peerConnections[peerID] = PeerConnection(
            targetPeerId: peerID,
            state: .invited,
            session: globalSession
        )

        invitationHandler(true, globalSession)
    }
}

extension MultipeerCommunicator: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser,
                 foundPeer peerID: MCPeerID,
                 withDiscoveryInfo info: [String : String]?) {
        let advertisedConnection = PeerConnection(
            targetPeerId: peerID,
            state: .invited,
            session: globalSession
        )
        peerConnections[peerID] = advertisedConnection
        browser.invitePeer(
            peerID,
            to: globalSession,
            withContext: ConnectionData.message("Greetings from the other side").toData,
            timeout: 10.0
        )
    }

    func browser(_ browser: MCNearbyServiceBrowser,
                 lostPeer peerID: MCPeerID) {
        guard let peer = peerConnections[peerID] else {
            print("Lost a peer we didn't known about", peerID, peerConnections)
            return
        }
        print("\(peerID) is no longer connected")
        peer.state = .notConnected
    }

    func browser(_ browser: MCNearbyServiceBrowser,
                 didNotStartBrowsingForPeers error: Error) {
        print("Failed browsing for peers", error)
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
