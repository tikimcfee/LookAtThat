//
//  PersistentThreadGroup.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 5/1/22.
//

import Foundation

// MARK: Thread->Tracer group

typealias StorageCollectionType = NSMutableArray
typealias StorageCollectionDowncast = NSArray
typealias StorageElement = TraceLine

class PersistentThreadGroup {
    static var defaultMapFile: URL { AppFiles.getDefaultTraceMapFile() }
    
    private var allErrorQueues = ConcurrentArray<String>()
    private let tracerMap = ConcurrentDictionary<String, PersistentThreadTracer>()
    
    var lastSkipSignature: String?
    var sharedSignatureMap = TraceLineIDMap()
    
    init() {
        reloadTraceMap()
    }
    
    func tracer(for queueName: String) -> PersistentThreadTracer? {
        guard !allErrorQueues.values.contains(queueName) else { return nil }
        
        do {
            return try tracerMap[queueName] ?? {
                let idFileName = probablySafeQueueName(queueName)
                let newTracer = try createNewTracer(fileName: idFileName)
                tracerMap[queueName] = newTracer
                print("Created new thread tracer: \(newTracer)")
                return newTracer
            }()
        } catch {
            print("Tracer could not be created: \(queueName), \(error)")
            allErrorQueues.append(queueName)
            return nil
        }
    }
}

//MARK: - Data loading
extension PersistentThreadGroup {
    func reloadTraceMap() {
        do{
            sharedSignatureMap = try TraceLineIDMap.decodeFrom(file: Self.defaultMapFile)
        } catch {
            print(error)
        }
    }
    
    func eraseTraceMap() {
        AppendingStore(targetFile: Self.defaultMapFile).cleanFile()
        reloadTraceMap()
    }
    
    func commitTraceMapToTarget() -> Bool {
        do {
            let snapshot = try sharedSignatureMap.encodeValues()
            try snapshot.write(to: Self.defaultMapFile, options: .atomic)
            return true
        } catch {
            print("TraceIDMap snapshot error", error)
            return false
        }
    }
}

private extension PersistentThreadGroup {
    func probablySafeQueueName(_ queue: String) -> String {
        queue.components(separatedBy:
            .alphanumerics
            .inverted
        ).joined(separator: "_")
    }
    
    func probablySafeThreadName(_ thread: Thread) -> String {
        thread.threadName.components(separatedBy:
            .alphanumerics
            .inverted
        ).joined(separator: "_")
    }
    
    func createNewTracer(fileName: String) throws -> PersistentThreadTracer {
        print("Creating new thread tracer: \(fileName)")
        let newIDFile = AppFiles.createTraceIDFile(named: fileName)
        return try PersistentThreadTracer(
            idFileTarget: newIDFile,
            sourceMap: sharedSignatureMap,
            traceDelegate: TracingRoot.shared
        )
    }
}

#if os(iOS)
class TracingRoot: TraceDelegate {
    static let shared = TracingRoot()
    var writesEnabled: Bool = false
    private init() { }
}
#endif
