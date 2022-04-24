//
//  TraceLog.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 4/23/22.
//

import Foundation
import SwiftTrace
import SwiftSyntax
import AppKit

class TracingRoot {
    static var shared = TracingRoot()
    
    var logOutput = ConcurrentArray<TraceOutput>()
    
    private init() {
        
    }
    
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
            CodeGrid.AttributedGlyphs.self,
            SemanticInfoBuilder.self,
            GridCache.self,
            GlyphLayerCache.self
        ] as [AnyClass]
        
        types.forEach {
            SwiftTrace.trace(aClass: $0)
            let parser = SwiftTrace.interpose(aType: $0)
            print("interposed '\($0)': \(parser)")
        }
    }
    
    func onLog(_ out: TraceOutput) {
        logOutput.append(out)
    }
}

extension TraceOutput {
    private static let Module = "LookAtThat_AppKit."
    private static let CallSeparator = " -> "
    private static let TypeSeparator = " : "
    
    var name: String {
        switch self {
        case .entry: return "-> "
        case .exit:  return "<- "
        }
    }
    
    func cleanFunction(_ rawFunction: String) -> String {
        let argIndex = rawFunction.firstIndex(of: "(") ?? rawFunction.endIndex
        let strippedArgs = rawFunction.prefix(upTo: argIndex)
        return String(strippedArgs)
    }
    
    func cleanModule(_ line: String) -> String {
        line.replacingOccurrences(of: Self.Module, with: "")
    }
    
    var callComponents: (callPath: String, returnType: String) {
        let splitFunction = decorated.components(separatedBy: Self.CallSeparator)
        if splitFunction.count == 2 {
            let rawFunction = splitFunction[0]
            let strippedArgs = cleanModule(
                cleanFunction(rawFunction)
            )
            return (String(strippedArgs), splitFunction[1])
        }
        
        let splitField = decorated.components(separatedBy: Self.TypeSeparator)
        if splitField.count == 2 {
            return (cleanModule(splitField[0]), splitField[1])
        }
        
        return (decorated, "")
    }
}
