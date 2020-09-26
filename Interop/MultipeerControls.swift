import MultipeerConnectivity
import Foundation

extension MultipeerConnectionManager {
    func startBrowser() {
        serviceBrowser.startBrowsingForPeers()
    }

    func startAdvertiser() {
        serviceAdvertiser.startAdvertisingPeer()
    }

    func send(message: String, to peer: MCPeerID) {
        let currentConnection = peerConnections
        workerQueue.async {
            guard currentConnection[peer] != nil else {
                print("Stop making up peer ids", peer)
                return
            }

            let quickMessage = ConnectionData.message(message).toData

            do {
                try self.globalSession.send(quickMessage, toPeers: [peer], with: .reliable)
            } catch {
                print("Send failed", error)
            }
        }
    }
}
