import Foundation
import MultipeerConnectivity


enum StreamError: Error {
    case readError(error: Error?, partialData: [UInt8])
}

struct PreparedOutputStream {
    let stream: OutputStream
    func send(_ data: Data) {
        let streamedBytes = stream.writeDataWithBoundPointer(data)
        print("Stream finished with written bytes [\(streamedBytes)]")
    }
}

typealias PreparedStreamReceiver = (PreparedOutputStream) -> Void

extension ConnectionBundle {

    func makeOutputStream(for peer: MCPeerID, _ receiver: @escaping PreparedStreamReceiver) {
        streamWorker.run {
            guard let newOutputStream = self.createStream(for: peer) else { return }
            print("Stream created '\(newOutputStream.description)' - scheduling in \(Thread.current)-\(RunLoop.current)")
            newOutputStream.schedule(in: .current, forMode: .default)
            newOutputStream.open()
            receiver(
                PreparedOutputStream(stream: newOutputStream)
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
