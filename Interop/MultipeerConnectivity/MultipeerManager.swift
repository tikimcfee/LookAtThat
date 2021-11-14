import Foundation
import MultipeerConnectivity
import Combine
import SwiftUI

typealias MessageHistory = AutoListValueDict<MCPeerID, String>

class MultipeerConnectionManager: NSObject, ObservableObject {
    public static let shared = MultipeerConnectionManager()
    let workerQueue = DispatchQueue(label: "MultipeerManager", qos: .userInitiated)
    let mainQueue = DispatchQueue.main
    let sheetDataTransformer = WireDataTransformer()

    // Multipeer API setup
    var currentConnection = ConnectionBundle()
    lazy var multipeerStreamController: MultipeerStreamController = {
        let streamController = MultipeerStreamController(currentConnection, self)
        streamController.onStreamDataReady = self.onStreamDataReady(_:)
        return streamController
    }()

    // Our models and streams
    @Published var sentMessages = MessageHistory()
    @Published var receivedMessages = MessageHistory()

    @Published var currentPeers = [MCPeerID: PeerConnection]()
    @Published var peerDiscoveryState = MultipeerStateViewModel()
    @Published var receivedCodeSheets = [CodeSheet]()
    @Published var receivedCodeGrids = [Data]()
    @Published var outputStreamBiMap = BiMap<PreparedOutputStream, Stream>()
    @Published var inputStreamBiMap = BiMap<ReceivedInputStream, Stream>()

    lazy var peerStream = $currentPeers.share().eraseToAnyPublisher()
    lazy var stateStream = $peerDiscoveryState.share().eraseToAnyPublisher()
    lazy var codeSheetStream = $receivedCodeSheets.share().eraseToAnyPublisher()
    lazy var codeGridStream = $receivedCodeGrids.share().eraseToAnyPublisher()
    lazy var outputStreams = $outputStreamBiMap.share().eraseToAnyPublisher()
    lazy var inputStreams = $inputStreamBiMap.share().eraseToAnyPublisher()

    private override init() {
        super.init()
        peerDiscoveryState = makeNewDiscoveryState()
        currentConnection.delegate = self
    }

    func makeNewDiscoveryState() -> MultipeerStateViewModel {
        return MultipeerStateViewModel(
            displayName: currentConnection.myPeerId.displayName,
            isBrowsing: currentConnection.isBrowsing,
            isAdvertising: currentConnection.isAdvertising
        )
    }
}

// MARK: - CodeGrid Stream Parsing
extension MultipeerConnectionManager {
    func onStreamDataReady(_ data: Data) {
        print("Handling received stream of size \(data.count)")
        
        guard let decompressed = sheetDataTransformer.decompress(data) else {
            print("StreamReady call could not be decompressed. Well that sucks.")
            return
        }
        
        receivedCodeGrids.append(decompressed)
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
