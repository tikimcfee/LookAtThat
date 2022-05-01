//
//  ThreadTracing.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 4/29/22.
//

import Foundation

#if !TARGETING_SUI && !os(iOS)
import SwiftTrace
#endif

typealias ThreadStorageRootType = NSMutableArray
typealias ThreadStorageTypeDowncast = NSArray
typealias ThreadStorageObjectType = TraceLine

class DirectedThreadLogger {
    private static let newLine = "\n"
    
    let fileReader: SplittingFileReader
    let store: AppendingStore
    
    init(fileReader: SplittingFileReader,
         store: AppendingStore) {
        self.fileReader = fileReader
        self.store = store
    }
    
    static var AllWritersEnabled = false
    
    func consume(_ line: TraceLine) {
        guard Self.AllWritersEnabled else { return }
        
        let serialized = line.serialize()
        store.appendText(serialized)
        store.appendText(Self.newLine)
    }
}

extension Thread {
    private static let fileIOStorage = ConcurrentDictionary<Thread, DirectedThreadLogger>()
    private static let logStorage = ConcurrentDictionary<Thread, ThreadStorageRootType>()
    private static let threadNameStorage = ConcurrentDictionary<Thread, String>()
    
    func getTraceLogs() -> [ThreadStorageObjectType] {
        let capturedType = Self.logStorage[self]
        let maybeArray = capturedType as? [ThreadStorageObjectType]
        return maybeArray ?? []
    }
    
    static func removeAllLogTraces() {
        AppFiles.allTraceFiles().forEach {
            print("Removing log file ", $0.lastPathComponent)
            AppendingStore(targetFile: $0).cleanFile()
        }
    }
    
    static func loadPersistedTrace(at url: URL) -> [TraceLine] {
        let target = NSMutableArray()
        SplittingFileReader(targetURL: url)
            .cancellableRead { newLine, shouldStop in
                guard let traceLine = TraceLine.deserialize(traceLine: newLine) else {
                    print("Trace line failed to deserialize: \(newLine)")
                    shouldStop = true
                    return
                }
                target.add(traceLine)
            }
        let mappedArray = target as NSArray as? [TraceLine]
        return mappedArray ?? {
            print("Failed to cast trace line array")
            return []
        }()
    }
    
    static func storeTraceLine(_ output: TraceLine) {
        let thread = Thread.current
        storageForThread(thread).add((output, thread))
    }
    
    static func storeTraceLog(_ output: TraceOutput) {
        let thread = Thread.current
        let outputStore = storageForThread(thread)
        
        // Skip storing functions with the same decorated signature
        if let last = outputStore.lastObject as? ThreadStorageObjectType,
           last.signature == output.signature {
            return
        }
        
        // re-cast avoids headache with bad insertions in untyped NSMutableArray
        let line = TraceLine(
            entryExitName: output.entryExitName,
            signature: output.signature,
            threadName: thread.threadName,
            queueName: currentQueueName()
        )
        let tuple = line
        let safeTuple = tuple as ThreadStorageObjectType
        
        // Store in memory, write to FileIO
        outputStore.add(safeTuple)
        fileIOFor(thread, line).consume(line)
    }
    
    private static func storageForThread(_ thread: Thread) -> ThreadStorageRootType {
        logStorage[thread] ?? {
            let type = ThreadStorageRootType()
            logStorage[thread] = type
            return type
        }()
    }
    
    private static func fileIOFor(_ thread: Thread, _ traceLine: TraceLine) -> DirectedThreadLogger {
        fileIOStorage[thread] ?? {
            let targetTraceFileURL = AppFiles.createTraceFile(named: traceLine.queueName)
            let logger = DirectedThreadLogger(
                fileReader: SplittingFileReader(targetURL: targetTraceFileURL),
                store: AppendingStore(targetFile: targetTraceFileURL)
            )
            fileIOStorage[thread] = logger
            return logger
        }()
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
