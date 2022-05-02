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
    
    private var allErrorThreads = ConcurrentArray<Thread>()
    private let tracerMap = ConcurrentDictionary<Thread, PersistentThreadTracer>()
    let sharedSignatureMap = TraceLineIDMap()
    
    init() {
        reloadTraceMap()
    }

    func tracer(for thread: Thread) -> PersistentThreadTracer? {
        guard !allErrorThreads.values.contains(thread) else { return nil }
        
        do {
            return try tracerMap[thread] ?? {
                let idFileName = probablySafeThreadName(thread)
                let newTracer = try createNewTracer(fileName: idFileName)
                tracerMap[thread] = newTracer
                print("Created new thread tracer: \(newTracer)")
                return newTracer
            }()
        } catch {
            print("Tracer could not be created: \(thread), \(error)")
            allErrorThreads.append(thread)
            return nil
        }
    }
}

//MARK: - Data loading
extension PersistentThreadGroup {
    func reloadTraceMap() {
        sharedSignatureMap.decodeAndReload(from: Self.defaultMapFile)
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
            sourceMap: sharedSignatureMap
        )
    }
}
