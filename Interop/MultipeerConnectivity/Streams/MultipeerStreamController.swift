import Foundation
import MultipeerConnectivity

//MARK: - External controls
extension MultipeerStreamController {
    func streamMessage(to peer: MCPeerID, _ message: String) {
        WorkerPool.shared.nextWorker().async {
            let maybeStream = self.manager.outputStreamBiMap
                    .keysToValues.keys.first { $0.target == peer }

            guard let stream = maybeStream?.stream,
                  let utfData = message.data(using: .utf8) else {
                print("No open output stream for \(peer), or bad message '\(message)'")
                return
            }

            let written = stream.writeDataWithBoundPointer(utfData)
            print("Well.. it... says it was written. \(written)")
        }
    }
    
    func streamRaw(to peer: MCPeerID, _ data: Data) {
        WorkerPool.shared.nextWorker().async {
            let maybeStream = self.manager.outputStreamBiMap
                .keysToValues.keys.first { $0.target == peer }
            
            guard let stream = maybeStream?.stream else {
                      print("No open output stream for \(peer)")
                      return
                  }
            
            let written = stream.writeDataWithBoundPointer(data)
            print("Well.. it... says it was written. \(written)")
        }
    }

    func openStream(to peer: MCPeerID, _ receiver: @escaping OutputStreamReceiver) {
        bundle.makeOutputStream(for: peer) { newOutputStream in
            DispatchQueue.main.async {
                self.manager.outputStreamBiMap[newOutputStream] = newOutputStream.stream
                newOutputStream.stream.delegate = self
                newOutputStream.stream.open()
                receiver(newOutputStream)
            }
        }
    }

    func prepareInputStream(from peer: MCPeerID, in stream: InputStream) {
        bundle.prepareInputStream(for: peer, stream) { newInputStream in
            DispatchQueue.main.async {
                self.manager.inputStreamBiMap[newInputStream] = newInputStream.stream
                newInputStream.stream.delegate = self
                newInputStream.stream.open()
            }
        }
    }
}

//MARK: - Setup
class MultipeerStreamController: NSObject {

    private let stateQueue = DispatchQueue(label: "StreamController")
    let bundle: ConnectionBundle
    let manager: MultipeerConnectionManager
    
    var onStreamDataReady: ((Data) -> Void)?

    init(_ bundle: ConnectionBundle,
         _ manager: MultipeerConnectionManager) {
        self.bundle = bundle
        self.manager = manager
    }
    
    private func streamOpened(_ stream: Stream) {
        print("Stream opened - \(stream)")
        stateQueue.async {
            if let inputStream = stream as? InputStream {
                guard let openStream = self.manager.inputStreamBiMap[inputStream] else {
                    print("We missed an input stream somehow!")
                    return
                }
                print("InputStream to '\(openStream.target.displayName)' opened")
                
                QuickLooper(loop: { print(stream.whyIsItBroken) } )
                    .runUntil { stream.streamError != nil || stream.streamStatus == .atEnd }
                
            } else if let outputStream = stream as? OutputStream {
                guard let openStream = self.manager.outputStreamBiMap[outputStream] else {
                    print("We missed an output stream somehow!")
                    return
                }
                print("OutputStream to '\(openStream.target.displayName)' opened")
            }
        }
    }

    private func streamReportedHasBytes(_ stream: Stream) {
        print("Stream reporting bytes, starting process")
        guard let knownPeer = manager.inputStreamBiMap[stream] else {
            print("Missing input stream source; dropping request")
            return
        }

        let reader = InputStreamReader(stream: knownPeer.stream)
        let streamedData = try? reader.readData()
        guard let data = streamedData else {
            print("Failed to read streamed data")
            return
        }
        
        print("Stream data read, emitting to delegate")
        onStreamDataReady?(data)
//        let text = String(data: data, encoding: .utf8) ?? "nil"
//        print("Did we get a message??\n\t ->>> \(text)")
    }

    private func streamReportedHasSpace(_ stream: Stream) {
        print("Stream reported space...")
    }

    private func streamEnded(_ stream: Stream) {
        print("Stream ended - \(stream)")
        stateQueue.async {
            guard let openStream = self.manager.outputStreamBiMap[stream] else {
                print("No recorded stream!")
                return
            }
            print("Stream to '\(openStream.target.displayName)' ended")
        }
    }

    private func streamError(_ stream: Stream) {
        print("!! Stream error - \(String(describing: stream.streamError))")
        stateQueue.async {
            guard let openStream = self.manager.outputStreamBiMap[stream] else {
                print("No recorded stream for error!")
                return
            }
            print("Stream to '\(openStream.target.displayName)' errored.")
        }
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

