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
    
    var logOutput = ConcurrentArray<(TraceOutput, String)>()
    
    private init() {
        
    }
    
    func onLog(_ out: TraceOutput) {
        logOutput.append((out, String(describing: Thread.current)))
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
            CodeGrid.AttributedGlyphs.self,
//            CodeGridTokenCache.self,
//            GlyphLayerCache.self,
            ConcurrentGridRenderer.self,
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
