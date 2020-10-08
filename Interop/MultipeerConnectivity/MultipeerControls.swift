import MultipeerConnectivity
import Foundation

// MARK: - Connection setup
extension MultipeerConnectionManager {
    func startBrowser() {
        workerQueue.async {
            self.currentConnection.startBrowsing()
            self.updatePeerState()
        }
    }

    func startAdvertiser() {
        workerQueue.async {
            self.currentConnection.startAdvertising()
            self.updatePeerState()
        }
    }

    func setDisplayName(to newName: String) {
        workerQueue.async {
            self.onQueueSetDisplayName(newName)
            self.updatePeerState()
        }
    }

    private func updatePeerState() {
        mainQueue.async {
            self.peerDiscoveryState = self.makeNewDiscoveryState()
        }
    }
}


// MARK: - Communication
extension MultipeerConnectionManager {
    func sendCodeSheet(to peer: MCPeerID) {
        workerQueue.async {
            // Lol look at that dependency chain....
            guard let clickedSheet =
                    SceneLibrary.global.codePagesController
                        .touchState.mouse.currentClickedSheet
            else { return }
            self.onQueueSendSheet(clickedSheet, peer)
            self.updatePeerState()
        }
    }

    func send(message: String, to peer: MCPeerID) {
        workerQueue.async {
            self.onQueueSendMessage(message, peer)
            self.updatePeerState()
        }
    }
}

// MARK: - Block implementations
extension MultipeerConnectionManager {
    private func onQueueSendSheet(_ sheet: CodeSheet, _ peer: MCPeerID) {
        guard currentPeers[peer] != nil else {
            print("Stop making up peer ids", peer)
            return
        }

        guard let sheetData = sheetDataTransformer.data(from: sheet) else {
            print("Sheet data failed to send: \(sheet.id)")
            return
        }

        currentConnection.send(sheetData, to: peer)
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
            self.updatePeerState()
        }
    }

    private func onQueueSetDisplayName(_ newName: String) {
        let oldConnection = currentConnection
        oldConnection.shutdown()
        currentConnection = ConnectionBundle(newName)
        currentConnection.delegate = self
        mainQueue.async {
            self.currentPeers = [MCPeerID: PeerConnection]()
            if oldConnection.isAdvertising {
                self.startAdvertiser()
            }
            if oldConnection.isBrowsing {
                self.startBrowser()
            }
        }
    }
}
