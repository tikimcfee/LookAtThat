import MultipeerConnectivity
import Foundation

extension MultipeerConnectionManager: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        guard let connection = peerConnections[peerID] else {
            print("Received a state change without known peer.", peerConnections)
            return
        }

        let newState = PeerConnectionState.forState(state)
        print("State changed to \(newState): \(connection)")
        connection.state = newState
        sendUpdate()
    }

    // Received data from remote peer.
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        guard case let .message(messageData) = ConnectionData.fromData(data) else {
            let utf8Data = String(data: data, encoding: .utf8) ?? "<read_data_failed>"
            print("Failed to parse recevied data for \(peerID)::\(utf8Data)")
            return
        }
        print("Got new data", messageData)
        sendUpdate()
    }

    // Received a byte stream from remote peer.
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {

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
