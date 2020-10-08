import Foundation
import MultipeerConnectivity
import SystemConfiguration

typealias BundledDelegate = NSObject
    & MCSessionDelegate
    & MCNearbyServiceBrowserDelegate
    & MCNearbyServiceAdvertiserDelegate

class ConnectionBundle {
    var myPeerId: MCPeerID
    var globalSession: MCSession
    var serviceBrowser: MCNearbyServiceBrowser
    var serviceAdvertiser: MCNearbyServiceAdvertiser
    var isBrowsing = false
    var isAdvertising = false
    let streamWorker = BackgroundWorker()

    weak var delegate: BundledDelegate? {
        didSet {
            globalSession.delegate = delegate
            serviceBrowser.delegate = delegate
            serviceAdvertiser.delegate = delegate
        }
    }

    init(_ requestedDisplayName: String? = nil) {
        let peerId = Self.createPeerId(requestedDisplayName)
        self.myPeerId = peerId
        self.globalSession = Self.createSession(peerId)
        self.serviceBrowser = Self.createBrowser(peerId)
        self.serviceAdvertiser = Self.createAdvertiser(peerId)
    }

    func startBrowsing() {
        guard !isBrowsing else {
            print("Already browsing")
            return
        }
        isBrowsing = true
        serviceBrowser.startBrowsingForPeers()
    }

    func stopBrowsing() {
        guard isBrowsing else {
            print("Not browsing")
            return
        }
        isBrowsing = false
        serviceBrowser.stopBrowsingForPeers()
    }

    func startAdvertising() {
        guard !isAdvertising else {
            print("Already advertising")
            return
        }
        isAdvertising = true
        serviceAdvertiser.startAdvertisingPeer()
    }

    func stopAdvertising() {
        guard isAdvertising else {
            print("Not advertising")
            return
        }
        isAdvertising = false
        serviceAdvertiser.stopAdvertisingPeer()
    }

    func send(_ data: Data, to peer: MCPeerID) {
        do {
            try globalSession.send(data, toPeers: [peer], with: .reliable)
        } catch {
            print("Failed to send to \(peer)", error)
        }
    }

    func shutdown() {
        streamWorker.stop()
        serviceAdvertiser.stopAdvertisingPeer()
        serviceAdvertiser.delegate = nil
        isAdvertising = false
        serviceBrowser.stopBrowsingForPeers()
        serviceBrowser.delegate = nil
        isBrowsing = false

        // If things start getting screwy again, bust this out
        // (screwy = ghost sessions and peers, neverending connections, 'weird states')
//        globalSession.connectedPeers.forEach {
//            globalSession.cancelConnectPeer($0)
//        }
        globalSession.delegate = nil
    }

    private static func createPeerId(_ requestedDisplayName: String? = nil) -> MCPeerID {
        let displayName: String
        if let requested = requestedDisplayName {
            displayName = UserKeys.peerDisplayName.save(value: requested)
        } else {
            displayName = UserKeys.peerDisplayName.safeValue(using: Self.defaultDeviceName)
        }
        return MCPeerID(displayName: displayName)
    }

    private static func createSession(_ peerId: MCPeerID) -> MCSession {
        let session = MCSession(
            peer: peerId,
            securityIdentity: nil,
            encryptionPreference: .none
        )
        return session
    }

    private static func createBrowser(_ peerId: MCPeerID) -> MCNearbyServiceBrowser {
        let browser = MCNearbyServiceBrowser(
            peer: peerId,
            serviceType: Self.kServiceName
        )
        return browser
    }

    private static func createAdvertiser(_ peerId: MCPeerID) -> MCNearbyServiceAdvertiser {
        let advertisier = MCNearbyServiceAdvertiser(
            peer: peerId,
            discoveryInfo: nil,
            serviceType: Self.kServiceName
        )
        return advertisier
    }

    private static var newDiscoveryInfo: [String: String] {
        return ["advertiserStart": Date().description]
    }
    private static let kServiceName = "latmacconn"
    private static var defaultDeviceName: String {
        #if os(OSX)
        let cfComputerName = SCDynamicStoreCopyComputerName(nil, nil)
        let name = (cfComputerName as String? ?? "unknown-macOS-App")
            .appending("-")
            .appending(UUID().uuidString)
        return name
        #elseif os(iOS)
        return "\(UIDevice.current.name)-".appending(UUID().uuidString)
        #endif
    }
}

enum UserKeys: String {
    case peerDisplayName

    func save(value: String) -> String {
        UserDefaults.standard.setValue(value, forKey: self.rawValue)
        return value
    }

    private func savedValue() -> String? {
        return UserDefaults.standard.string(forKey: self.rawValue)
    }

    func safeValue(using defaultValue: String) -> String {
        return savedValue() ?? {
            return save(value: defaultValue)
        }()
    }
}
