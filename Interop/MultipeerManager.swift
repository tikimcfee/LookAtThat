import Foundation
import MultipeerConnectivity
import Combine
import SwiftUI

typealias MessageHistory = AutoListValueDict<MCPeerID, String>

class MultipeerConnectionManager: NSObject, ObservableObject {
    public static let shared = MultipeerConnectionManager()
    let workerQueue = DispatchQueue(label: "MultipeerManager", qos: .userInitiated)

    // Multipeer API setup
    var currentConnection = ConnectionBundle()

    // Our models and streams
    @Published var sentMessages = MessageHistory()
    @Published var receivedMessages = MessageHistory()

    @Published var currentPeers = [MCPeerID: PeerConnection]()
    @Published var peerDiscoveryState = MultipeerStateViewModel()

    lazy var peerStream = $currentPeers.share()

    lazy var connectionStateStream =
        $currentPeers.share().eraseToAnyPublisher()

    private override init() {
        super.init()
        currentConnection.delegate = self
    }
}

// MARK: - Advertiser Delegate
extension MultipeerConnectionManager: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser,
                    didReceiveInvitationFromPeer peerID: MCPeerID,
                    withContext context: Data?,
                    invitationHandler: @escaping (Bool, MCSession?) -> Void) {

        guard currentPeers[peerID] == nil else {
            print("Received an invitation from an existing connection, may be a reconnection attempt")
            return
        }

        if let data = context {
            let connectionContext = ConnectionData.fromData(data)
            print("Connection context: ", connectionContext)
        }

        currentPeers[peerID] = PeerConnection(
            targetPeerId: peerID,
            state: .invited
        )

        invitationHandler(true, currentConnection.globalSession)
    }
}

// MARK: - Browser Delegate
extension MultipeerConnectionManager: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser,
                 foundPeer peerID: MCPeerID,
                 withDiscoveryInfo info: [String : String]?) {
        let advertisedConnection = PeerConnection(
            targetPeerId: peerID,
            state: .invited
        )
        currentPeers[peerID] = advertisedConnection
        browser.invitePeer(
            peerID,
            to: currentConnection.globalSession,
            withContext: nil,
            timeout: 10.0
        )
    }

    func browser(_ browser: MCNearbyServiceBrowser,
                 lostPeer peerID: MCPeerID) {
        guard let peer = currentPeers[peerID] else {
            print("Lost a peer we didn't known about", peerID, currentPeers)
            currentPeers[peerID] = PeerConnection(
                targetPeerId: peerID,
                state: .lost
            )
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
