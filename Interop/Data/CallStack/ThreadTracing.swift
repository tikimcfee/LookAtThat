//
//  ThreadTracing.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 4/29/22.
//

import Foundation

#if !TARGETING_SUI
import SwiftTrace
#endif

typealias ThreadStorageRootType = NSMutableArray
typealias ThreadStorageTypeDowncast = NSArray
typealias ThreadStorageObjectType = (out: TraceLine, thread: Thread)

extension Thread {
    static let logStorage = ConcurrentDictionary<Thread, ThreadStorageRootType>()
    static let threadNameStorage = ConcurrentDictionary<Thread, String>()
    
    func getTraceLogs() -> [ThreadStorageObjectType] {
        let capturedType = Self.logStorage[self]
        let maybeArray = capturedType as? [ThreadStorageObjectType]
        return maybeArray ?? []
    }
    
    static func storeTraceLog(_ output: TraceOutput) {
        let thread = Thread.current
        let outputStore = logStorage[thread] ?? {
            let type = ThreadStorageRootType()
            logStorage[thread] = type
            return type
        }()
        
        // Skip storing functions with the same decorated signature
        if let last = outputStore.lastObject as? ThreadStorageObjectType,
           last.out.signature == output.signature {
            return
        }
        
        // re-cast avoids headache with bad insertions in untyped NSMutableArray
        let line = TraceLine(
            entryExitName: output.entryExitName,
            signature: output.signature,
            threadName: thread.threadName,
            queueName: currentQueueName()
        )
        let tuple = (line, thread)
        let safeTuple = tuple as ThreadStorageObjectType
        outputStore.add(safeTuple)
    }
    
    var threadName: String {
        if let name = Self.threadNameStorage[self] { return name }
        let threadName: String
        if isMainThread {
            threadName = "main"
        } else if let directName = Thread.current.name, !directName.isEmpty {
            threadName = directName
        } else {
            let info = ThreadInfoExtract.from(description)
            threadName = info.number
        }
        Self.threadNameStorage[self] = threadName
        return threadName
    }
}
