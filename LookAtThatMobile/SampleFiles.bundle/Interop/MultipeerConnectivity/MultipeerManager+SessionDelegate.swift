import MultipeerConnectivity
import Foundation

extension MultipeerConnectionManager: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        guard let connection = currentPeers[peerID] else {
            print("Received a state change without known peer.", currentPeers)
            return
        }

        let newState = PeerConnectionState.forState(state)
        print("State changed to \(newState): \(connection)")
        connection.state = newState

        mainQueue.async {
            self.objectWillChange.send()
        }
    }

    // Received data from remote peer.
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        let connectionData = ConnectionData.fromData(data)
        switch connectionData {
        case .error:
            print("Failed to parse data; got an error")
        case let .message(messageData):
            print("Message: ", messageData)
        }

    }

    // Received a byte stream from remote peer.
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        multipeerStreamController.prepareInputStream(from: peerID, in: stream)
    }

    // Start receiving a resource from remote peer.
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {

    }

    // Finished receiving a resource from remote peer and saved the content
    // in a temporary location - the app is responsible for moving the file
    // to a permanent location within its sandbox.
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {

    }

    // Made first contact with peer and have identity information about the
    // remote peer (certificate may be nil).
    func session(_ session: MCSession, didReceiveCertificate certificate: [Any]?, fromPeer peerID: MCPeerID, certificateHandler: @escaping (Bool) -> Void) {
        // Always accept certificates
        certificateHandler(true)
    }
}
