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
    static var defaultWriteEnableState = false
    
    lazy var capturedLoggingThreads = ConcurrentDictionary<Thread, Int>()
    lazy var capturedLoggingQueues = ConcurrentDictionary<String, Int>()
    let tracingConsumer = TracingRootConsumer()
    
    private init() {
        
    }
    
    func onLog(_ out: TraceOutput) {
        capturedLoggingThreads[Thread.current] = 1
        capturedLoggingQueues[currentQueueName()] = 1
        tracingConsumer.storeTraceLog(out)
    }
    
    func getCurrentQueueTraceLogs() -> PersistentThreadTracer? {
        tracingConsumer.getTraceLogs()
    }
    
    func loadTrace(from file: URL) throws -> PersistentThreadTracer {
        try tracingConsumer.threadTracer(from: file)
    }
    
    func addRandomEvent() {
        tracingConsumer.addRandomEvent()
    }
    
    func commitMappingState() {
        tracingConsumer.commitGroupTracerState()
    }
    
    func removeAllTraces() {
        tracingConsumer.removeAllLogTraces()
    }
    
    func removeMapping() {
        tracingConsumer.removeMapping()
    }
    
    func setWritingEnabled(isEnabled: Bool) {
        print("Setting thread tracer writer: isEnabled=\(isEnabled)")
        PersistentThreadTracer.AllWritesEnabled = isEnabled
    }
}

#if !TARGETING_SUI
import SwiftTrace
extension TracingRoot {
    static let trackedTypes: [AnyClass] = [
        CodeGrid.self,
        CodeGridParser.self,
//        CodeGrid.Measures.self,
//        CodeGrid.Renderer.self,
        CodeGridSemanticMap.self,
//        SemanticInfoBuilder.self,
//        CodeGrid.AttributedGlyphs.self,
//        CodeGridTokenCache.self,
        GridCache.self,
//        GlyphLayerCache.self,
        FileBrowser.self,
        ConcurrentGridRenderer.self,
        GridCache.self,
        WorkerPool.self,
        SceneLibrary.self,
        CodePagesController.self,
        WorldGridEditor.self,
        WorldGridSnapping.self,
        
//        TraceLineIDMap.self,
//        TraceLineIDMap.Serialized.self,
    ]
    
    func setupTracing() {
        SwiftTrace.logOutput.onOutput = onLog(_:)
        SwiftTrace.swiftDecorateArgs.onEntry = false
        SwiftTrace.swiftDecorateArgs.onExit = false
        SwiftTrace.typeLookup = true
        
        Self.trackedTypes.forEach {
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
