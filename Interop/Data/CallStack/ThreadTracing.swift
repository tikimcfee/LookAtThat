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

extension Thread {
    func getTraceLogs() -> PersistentThreadTracer? {
        Self.group.tracer(for: Thread.current)
    }
    
    static func storeTraceLog(_ output: TraceOutput) {
        group.multiplextNewOutput(
            thread: Thread.current,
            output: output
        )
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

extension Thread {
    private static let group = PersistentThreadGroup()
    private static let threadNameStorage = ConcurrentDictionary<Thread, String>()
}

extension Thread {
    static func commitGroupTracerState() {
        let commitSucceeded = group.commitTraceMapToTarget()
        print("Did commit trace map: \(commitSucceeded)")
        group.reloadTraceMap()
    }
    
    static func removeAllLogTraces() {
        AppFiles.allTraceFiles().forEach {
            print("Removing log file ", $0.lastPathComponent)
            AppendingStore(targetFile: $0).cleanFile()
        }
    }
    
    static func threadTracer(from url: URL) throws -> PersistentThreadTracer {
        try PersistentThreadTracer(
            idFileTarget: url,
            sourceMap: group.sharedSignatureMap
        )
    }
    
    static func addRandomEvent() {
        group.tracer(for: Thread.current)?
            .onNewTraceLine(TraceLine.random)
    }
}

//MARK: - SwiftTrace Bridge Extension


extension PersistentThreadGroup {
    func multiplextNewLine(thread: Thread, line: TraceLine) {
        guard let tracer = tracer(for: thread) else { return }
        tracer.onNewTraceLine(line)
    }
    
    func multiplextNewOutput(thread: Thread, output: TraceOutput) {
        guard let tracer = tracer(for: thread) else { return }
        
        let line = TraceLine(
            entryExitName: output.entryExitName,
            signature: output.signature,
            threadName: thread.threadName,
            queueName: currentQueueName()
        )
        tracer.onNewTraceLine(line)
    }
}
