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

class MultipeerConnectionManager: NSObject {
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
            state: .invited,
            session: globalSession
        )

        invitationHandler(true, globalSession)
    }
}

extension MultipeerConnectionManager: MCNearbyServiceBrowserDelegate {
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
