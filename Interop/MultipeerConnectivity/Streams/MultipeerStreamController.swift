import Foundation
import MultipeerConnectivity

//MARK: - External controls
extension MultipeerStreamController {
    func openStream(to peer: MCPeerID, _ receiver: @escaping PreparedStreamReceiver) {
        bundle.makeOutputStream(for: peer, receiver)
    }
}

//MARK: - Setup
class MultipeerStreamController: NSObject {

    let bundle: ConnectionBundle

    init(_ bundle: ConnectionBundle) {
        self.bundle = bundle
    }

    private func streamOpened(_ stream: Stream) {
        print("Stream opened - \(stream)")
    }

    private func streamReportedHasBytes(_ stream: Stream) {
//        print("Stream reported new bytes...")
    }

    private func streamReportedHasSpace(_ stream: Stream) {
//        print("Stream reported space...")
    }

    private func streamEnded(_ stream: Stream) {
        print("Stream ended - \(stream)")
    }

    private func streamError(_ stream: Stream) {
        print("!! Stream error - \(stream.streamError)")
    }

    private func streamReportedUnknownEvent(_ stream: Stream, _ code: Stream.Event) {
        print("!? Unknown stream event [\(code)] - \(stream)")
    }
}

extension MultipeerStreamController: StreamDelegate {
    func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        switch eventCode {
        case .openCompleted:
            streamOpened(aStream)
        case .hasSpaceAvailable:
            streamReportedHasSpace(aStream)
        case .hasBytesAvailable:
            streamReportedHasBytes(aStream)
        case .endEncountered:
            streamEnded(aStream)
        case .errorOccurred:
            streamError(aStream)
        default:
            streamReportedUnknownEvent(aStream, eventCode)
        }
    }
}

