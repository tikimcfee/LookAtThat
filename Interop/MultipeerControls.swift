import MultipeerConnectivity
import Foundation

extension MultipeerConnectionManager {

    func startBrowser() {
        workerQueue.async {
            self.currentConnection.startBrowsing()
            self.mainQueue.async {
                self.peerDiscoveryState.isBrowsing = true
            }
        }
    }

    func startAdvertiser() {
        workerQueue.async {
            self.currentConnection.startAdvertising()
            self.mainQueue.async {
                self.peerDiscoveryState.isAdvertising = true
            }
        }
    }

    func send(message: String, to peer: MCPeerID) {
        workerQueue.async {
            self.onQueueSendMessage(message, peer)
        }
    }

    func setDisplayName(to newName: String) {
        workerQueue.async {
            self.onQueueSetDisplayName(newName)
        }
    }

    private func onQueueSendMessage(_ message: String, _ peer: MCPeerID) {
        guard currentPeers[peer] != nil else {
            print("Stop making up peer ids", peer)
            return
        }

        let quickMessage = ConnectionData.message(message).toData
        currentConnection.send(quickMessage, to: peer)

        mainQueue.async {
            self.sentMessages[peer].append(message)
        }
    }

    private func onQueueSetDisplayName(_ newName: String) {
        let oldConnection = currentConnection
        oldConnection.shutdown()
        currentConnection = ConnectionBundle(newName)
        currentConnection.delegate = self
        mainQueue.async {
            self.currentPeers = [MCPeerID: PeerConnection]()
            self.peerDiscoveryState = MultipeerStateViewModel()
            if oldConnection.isAdvertising {
                self.startAdvertiser()
            }
            if oldConnection.isBrowsing {
                self.startBrowser()
            }
        }
    }
}

extension ConnectionBundle {
    func send(_ data: Data, to peer: MCPeerID) {
        do {
            try globalSession.send(data, toPeers: [peer], with: .reliable)
        } catch {
            print("Failed to send to \(peer)", error)
        }
    }
}
