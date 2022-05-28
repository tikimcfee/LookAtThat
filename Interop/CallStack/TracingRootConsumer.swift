//
//  TracingRootConsumer.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 5/3/22.
//

import Foundation

#if !TARGETING_SUI
import SwiftTrace
#endif

class TracingRootConsumer {
    private let group = PersistentThreadGroup()
    
    func getTraceLogs() -> PersistentThreadTracer? {
        group.tracer(for: currentQueueName())
    }
    
    func storeTraceLog(_ output: TraceOutput) {
        group.multiplextNewOutput(
            thread: Thread.current,
            queueName: currentQueueName(),
            output: output
        )
    }
    
    func commitGroupTracerState() {
        let commitSucceeded = group.commitTraceMapToTarget()
        print("Did commit trace map: \(commitSucceeded)")
        group.reloadTraceMap()
    }
    
    func removeAllLogTraces() {
        AppFiles.allTraceFiles().forEach {
            print("Removing log file ", $0.lastPathComponent)
            AppendingStore(targetFile: $0).cleanFile()
        }
    }
    
    func removeMapping() {
        group.eraseTraceMap()
    }
    
    func threadTracer(from url: URL) throws -> PersistentThreadTracer {
        try PersistentThreadTracer(
            idFileTarget: url,
            sourceMap: group.sharedSignatureMap,
            traceDelegate: TracingRoot.shared
        )
    }
    
    func addRandomEvent() {
        group
            .tracer(for: currentQueueName())?
            .onNewTraceLine(TraceLine.random)
    }
}

extension PersistentThreadGroup {
    func multiplextNewLine(
        thread: Thread,
        queueName: String,
        line: TraceLine
    ) {
        guard let tracer = tracer(for: queueName) else { return }
        tracer.onNewTraceLine(line)
    }
    
    func multiplextNewOutput(
        thread: Thread,
        queueName: String,
        output: TraceOutput
    ) {
        guard let tracer = tracer(for: queueName) else {
            print("\t\tMissing tracer for \(queueName)!")
            return
        }
        
        if output.isExit { return }
//        if lastSkipSignature == output.signature { return }
//        lastSkipSignature = output.signature
        
        let line = TraceLine(
            entryExitName: output.entryExitName,
            signature: output.signature,
            threadName: thread.threadName,
            queueName: currentQueueName()
        )
        
        tracer.onNewTraceLine(line)
    }
}
