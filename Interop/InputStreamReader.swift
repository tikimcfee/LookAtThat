//
//  InputStreamReader.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 5/8/22.
//

import Foundation

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
        
        QuickLooper(loop: printStream).runUntil { isFinalized }
        
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
