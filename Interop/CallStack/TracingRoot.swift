//
//  TraceLog.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 4/23/22.
//

import Foundation
import SwiftSyntax
import AppKit

extension TracingRoot: TraceDelegate {
    class State: ObservableObject {
        @Published var traceWritesEnabled = false
    }
    
    var writesEnabled: Bool {
        get { state.traceWritesEnabled }
        set {
            print("<!> Thread trace writes: enabled=\(newValue)")
            state.traceWritesEnabled = newValue
        }
    }
}

class TracingRoot {
    static var shared = TracingRoot()
    
    lazy var capturedLoggingThreads = ConcurrentDictionary<Thread, Int>()
    lazy var capturedLoggingQueues = ConcurrentDictionary<String, Int>()
    let tracingConsumer = TracingRootConsumer()
    let state = State()
    
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
}

#if !TARGETING_SUI
import SwiftTrace
extension TracingRoot {
    static let trackedTypes: [AnyClass] = [
        FileBrowser.self,
        CodeGridWorld.self,
        CodeGridGlobalSemantics.self,
        CodeGrid.self,
        CodeGridParser.self,
//        CodeGrid.Measures.self,
        CodeGrid.Renderer.self,
        SemanticInfoBuilder.self,
//        CodeGridSemanticMap.self,
        CodeGrid.AttributedGlyphs.self,
//        CodeGridTokenCache.self,
        GridCache.self,
        GlyphLayerCache.self,
        FileBrowser.self,
        ConcurrentGridRenderer.self,
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
