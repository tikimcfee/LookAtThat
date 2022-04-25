//
//  TraceLog.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 4/23/22.
//

import Foundation
import SwiftSyntax
import AppKit

#if !TARGETING_SUI
import SwiftTrace
#endif

class TracingRoot {
    static var shared = TracingRoot()
    
    lazy var logOutput: ConcurrentArray<(TraceOutput, Thread)> = {
        let log = ConcurrentArray<(TraceOutput, Thread)>()
        log.reserve(30_000)
        return log
    }()
    
    private init() {
        
    }
    
    func onLog(_ out: TraceOutput) {
        guard out.isEntry else { return }
        
        let logThread = Thread.current
        DispatchQueue.global(qos: .userInitiated).async {
            self.logOutput.append((out, logThread))
        }
    }
    
    func setupTracing() {
#if !TARGETING_SUI
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
#endif
    }
}
