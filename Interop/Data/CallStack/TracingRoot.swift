//
//  TraceLog.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 4/23/22.
//

import Foundation
import SwiftSyntax
import AppKit

class TracingRoot {
    static var shared = TracingRoot()
    
    lazy var capturedLoggingThreads = ConcurrentDictionary<Thread, Int>()
    
    private init() {
        
    }
    
    func onLog(_ out: TraceOutput) {
        guard out.isEntry else { return }
        
        capturedLoggingThreads[Thread.current] = 1
        Thread.storeTraceLog(out)
    }
}

#if !TARGETING_SUI
import SwiftTrace
extension TracingRoot {
    func setupTracing() {
        SwiftTrace.logOutput.onOutput = onLog(_:)
        SwiftTrace.swiftDecorateArgs.onEntry = false
        SwiftTrace.swiftDecorateArgs.onExit = false
        SwiftTrace.typeLookup = true
        
        let types = [
            CodeGrid.self,
            CodeGridParser.self,
            CodeGrid.Measures.self,
            CodeGrid.Renderer.self,
            CodeGridSemanticMap.self,
            SemanticInfoBuilder.self,
            //            CodeGrid.AttributedGlyphs.self,
            //            CodeGridTokenCache.self,
            //            GlyphLayerCache.self,
            //            ConcurrentGridRenderer.self,
            //            GridCache.self,
            //            WorkerPool.self,
            //            SceneLibrary.self,
            //            CodePagesController.self,
        ] as [AnyClass]
        
        types.forEach {
            SwiftTrace.trace(aClass: $0)
            let parser = SwiftTrace.interpose(aType: $0)
            print("interposed '\($0)': \(parser)")
        }
    }
}
#else
extension TracingRoot {
    func setupTracing() {
        print("\n\n\t\t Tracing is disabled!")
    }
}
#endif

typealias ThreadStorageType = NSMutableArray
typealias ThreadStorageTypeDowncast = NSArray
typealias ThreadStorageTuple = (out: TraceOutput, thread: Thread, queueName: String)

extension Thread {
    private static let logStorage = ConcurrentDictionary<Thread, ThreadStorageType>()
    
    func getTraceLogs() -> [ThreadStorageTuple] {
        let capturedType = Self.logStorage[self]
        let maybeArray = capturedType as? [ThreadStorageTuple]
        return maybeArray ?? []
    }
        
    static func storeTraceLog(_ output: TraceOutput) {
        let thread = Thread.current
        let outputStore = logStorage[thread] ?? {
            let type = ThreadStorageType()
            logStorage[thread] = type
            return type
        }()
        
        if let last = outputStore.lastObject as? ThreadStorageTuple,
           last.0.decorated == output.decorated {
            return
        }
        
        // re-cast avoids headache with bad insertions in untyped NSMutableArray
        let tuple = (output, thread, queueName)
        let safeTuple = tuple as ThreadStorageTuple
        outputStore.add(safeTuple)
    }
    
    var threadName: String {
        if isMainThread {
            return "main"
        } else if let threadName = Thread.current.name, !threadName.isEmpty {
            return threadName
        } else {
            let info = ThreadInfoExtract.from(description)
            return info.number
        }
    }
}

private var queueName: String {
    if let queueName = String(validatingUTF8: __dispatch_queue_get_label(nil)) {
        return queueName
    } else if let operationQueueName = OperationQueue.current?.name, !operationQueueName.isEmpty {
        return operationQueueName
    } else if let dispatchQueueName = OperationQueue.current?.underlyingQueue?.label, !dispatchQueueName.isEmpty {
        return dispatchQueueName
    } else {
        return "n/a"
    }
}
