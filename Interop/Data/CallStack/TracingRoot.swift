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
        capturedLoggingThreads[Thread.current] = 1
        Thread.storeTraceLog(out)
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
//        CodeGridSemanticMap.self,
//        SemanticInfoBuilder.self,
//        CodeGrid.AttributedGlyphs.self,
//        CodeGridTokenCache.self,
        GridCache.self,
        GlyphLayerCache.self,
        ConcurrentGridRenderer.self,
        GridCache.self,
//        WorkerPool.self,
        SceneLibrary.self,
        CodePagesController.self,
        WorldGridEditor.self,
        WorldGridSnapping.self,
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
