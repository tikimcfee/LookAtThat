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
        return data.withUnsafeBytes {
            guard let baseAddress = $0.bindMemory(to: UInt8.self).baseAddress else {
                print("Data could not be bound \(data)")
                return 0
            }
            return write(baseAddress, maxLength: data.count)
        }
    }
}

struct InputStreamReader {
    let stream: InputStream

    func readData() throws -> Data {
        let bufferSize = 1024
        var buffer = [UInt8](repeating: 0, count: bufferSize)
        var dataAccumulator: [UInt8] = []

        while true {
            let count = stream.read(&buffer, maxLength: buffer.capacity)

            guard count >= 0 else {
                stream.close()
                throw StreamError.readError(error: stream.streamError, partialData: dataAccumulator)
            }

            guard count != 0 else {
                stream.close()
                return Data(dataAccumulator)
            }

            dataAccumulator.append(contentsOf: buffer.prefix(count))
        }
    }
}
