import Foundation
import MultipeerConnectivity

enum StreamError: Error {
    case readError(error: Error?, partialData: [UInt8])
}

struct ReceivedInputStream: Identifiable, Hashable {
    let stream: InputStream
    let target: MCPeerID
    let id = UUID().uuidString

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(target)
    }
}

struct PreparedOutputStream: Identifiable, Hashable {
    let stream: OutputStream
    let target: MCPeerID
    let id = UUID().uuidString
    
    func send(_ data: Data) {
        let streamedBytes = stream.writeDataWithBoundPointer(data)
        print("Stream finished with written bytes [\(streamedBytes)]")
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(target)
    }
}

typealias OutputStreamReceiver = (PreparedOutputStream) -> Void
typealias InputStreamReceiver = (ReceivedInputStream) -> Void

extension ConnectionBundle {

    func prepareInputStream(for peer: MCPeerID, _ stream: InputStream, _ receiver: @escaping InputStreamReceiver) {
        streamWorker.run {
            stream.schedule(in: .current, forMode: .default)
            receiver(
                ReceivedInputStream(stream: stream, target: peer)
            )
        }
    }

    func makeOutputStream(for peer: MCPeerID, _ receiver: @escaping OutputStreamReceiver) {
        streamWorker.run {
            guard let newOutputStream = self.createStream(for: peer) else { return }
            print("Stream created '\(newOutputStream.description)' - scheduling in \(Thread.current)")
            newOutputStream.schedule(in: .current, forMode: .default)
            receiver(
                PreparedOutputStream(stream: newOutputStream, target: peer)
            )
        }
    }

    private func createStream(for peer: MCPeerID) -> OutputStream? {
        do {
            return try globalSession.startStream(withName: "default-stream", toPeer: peer)
        } catch {
            print("Failed to create stream to \(peer)", error)
            return nil
        }
    }
}

extension OutputStream {
    func writeDataWithBoundPointer(_ data: Data) -> Int {
        return data.withUnsafeBytes { bufferPointer in
            guard let baseAddress = bufferPointer.bindMemory(to: UInt8.self).baseAddress else {
                print("Data could not be bound \(data)")
                return 0
            }
            return write(baseAddress, maxLength: data.count)
        }
    }
}

struct QuickLooper {
    let loop: () -> Void
    func run(_ stop: @escaping () -> Bool) {
        guard !stop() else { return }
        DispatchQueue.main.async {
            loop()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                run(stop)
            }
        }
    }
}

extension Stream {
    var whyIsItBroken: String {
        let error = streamError?.localizedDescription ?? "nil error"
        let ioInput = (self as? InputStream)?.hasBytesAvailable
        let ioOutputSpace = (self as? OutputStream)?.hasSpaceAvailable
        let ioOut = "\(String(describing: ioInput)) ; \(String(describing: ioOutputSpace))"
        return "\(streamStatus.name) :: \(error) :: \(ioOut) :: \(self.description)"
    }
}

extension Stream.Status {
    var name: String {
        switch self {
        case .notOpen: return "notOpen"
        case .opening: return "opening"
        case .open: return "open"
        case .reading: return "reading"
        case .writing: return "writing"
        case .atEnd: return "atEnd"
        case .closed: return "closed"
        case .error: return "error"
        @unknown default: return "unknownDefault"
        }
    }
}

struct InputStreamReader {
    let stream: InputStream
    
    static let bufferSize = 16 * 1024
        
    func printStream() {
        print("<> monitor: \(stream.streamStatus) | \(stream.streamError?.localizedDescription ?? "nil err" ) | \(stream.hasBytesAvailable)")
    }

    func readData() throws -> Data {
        let bufferSize = Self.bufferSize
        var buffer = [UInt8](repeating: 0, count: bufferSize)
        
        var dataAccumulator: [UInt8] = []
        var isFinalized: Bool = false
        var finalizedData: Data {
            isFinalized = true
            return Data(dataAccumulator)
        }
        
        QuickLooper(loop: printStream).run { isFinalized }
        
        whileStreamHasBytes {
            let bufferSize = buffer.capacity
            let readCount = stream.read(&buffer, maxLength: bufferSize)
            
            switch readCount {
            // read error
            case -1:
                print("stream error during read")
                throw StreamError.readError(
                    error: stream.streamError,
                    partialData: dataAccumulator
                )
                
            // buffer end reached
            case 0:
                print("stream read 0; buffer EoF assumed")
                return true
            
            // append read data to final data blob
            default:
                dataAccumulator.append(contentsOf: buffer.prefix(readCount))
            }
            
            return false
        }
        
        return finalizedData
    }
    
    private func whileStreamHasBytes(_ readAction: @escaping () throws -> Bool) {
        print("starting stream bytes loop")
        while stream.hasBytesAvailable {
            do {
                let isReadActionComplete: Bool = try readAction()
                if isReadActionComplete {
                    print("read action reports done; breaking early")
                    break
                }
            } catch {
                print("Error during input stream read: \(error)")
            }
        }
    }
}

struct SourceFileStreamHandler {
    let inputStream: InputStream
    let outputStream: OutputStream
    
    func writeSourceFile(_ sourceFile: String) {
        
    }
}
