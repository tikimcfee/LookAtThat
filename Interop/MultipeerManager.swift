import Foundation
import MultipeerConnectivity
import Combine

typealias PeerMap = [MCPeerID: PeerConnection]

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

class MultipeerConnectionManager: NSObject {
    public static let shared = MultipeerConnectionManager()

    static let myPeerId: MCPeerID = {
        #if os(OSX)
        let defaultName = "lat-macos".appending(UUID().uuidString)
        #elseif os(iOS)
        let defaultName = "lat-ios".appending(UUID().uuidString)
        #endif
        let displayName = UserKeys.mcPeerId.safeValue(using: defaultName)
        return MCPeerID(displayName: displayName)
    }()

    lazy var discoveryInfo: [String:String] = {
        return [
            "testKey":"testValue"
        ]
    }()

    lazy var serviceBrowser: MCNearbyServiceBrowser = {
        let browser = MCNearbyServiceBrowser(peer: Self.myPeerId,
                                             serviceType: "latmacconn")
        browser.delegate = self
        return browser
    }()

    lazy var serviceAdvertiser: MCNearbyServiceAdvertiser  = {
        let browser = MCNearbyServiceAdvertiser(peer: Self.myPeerId,
                                                discoveryInfo: discoveryInfo,
                                                serviceType: "latmacconn")
        browser.delegate = self
        return browser
    }()

    lazy var globalSession: MCSession = {
        // TODO: encrypt that stuff boyo
        let session = MCSession(peer: Self.myPeerId, securityIdentity: nil, encryptionPreference: .none)
        session.delegate = self
        return session
    }()

    private lazy var connectionStream = CurrentValueSubject<PeerMap, Never>(peerConnections)
    lazy var sharedConnectionStream = connectionStream.share().eraseToAnyPublisher()
    var peerConnections = [MCPeerID: PeerConnection]()

    var workerQueue = DispatchQueue(label: "MultipeerManager", qos: .userInitiated)

    private override init() {
        super.init()
    }

    func sendUpdate() {
        connectionStream.send(peerConnections)
    }
}

extension MultipeerConnectionManager: MCNearbyServiceAdvertiserDelegate {
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
            state: .invited
        )

        invitationHandler(true, globalSession)
        sendUpdate()
    }
}

extension MultipeerConnectionManager: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser,
                 foundPeer peerID: MCPeerID,
                 withDiscoveryInfo info: [String : String]?) {
        let advertisedConnection = PeerConnection(
            targetPeerId: peerID,
            state: .invited
        )
        peerConnections[peerID] = advertisedConnection
        browser.invitePeer(
            peerID,
            to: globalSession,
            withContext: nil,
            timeout: 10.0
        )
        sendUpdate()
    }

    func browser(_ browser: MCNearbyServiceBrowser,
                 lostPeer peerID: MCPeerID) {
        guard let peer = peerConnections[peerID] else {
            print("Lost a peer we didn't known about", peerID, peerConnections)
            return
        }
        print("\(peerID) is no longer connected")
        peer.state = .notConnected
        sendUpdate()
    }

    func browser(_ browser: MCNearbyServiceBrowser,
                 didNotStartBrowsingForPeers error: Error) {
        print("Failed browsing for peers", error)
        sendUpdate()
    }
}
