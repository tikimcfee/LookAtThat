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
    
    var logOutput = [TraceOutput]()
    
    private init() {
        setupTracing()
    }
    
    private func setupTracing() {
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

enum TracedInfo {
    case missing(out: TraceOutput)
    case found(out: TraceOutput, info: SemanticInfo)
}

extension SemanticMapTracer {
    static func start(
        sourceGrids: [CodeGrid],
        sourceTracer: TracingRoot
    ) {
        SemanticMapTracer(
            sourceGrids: sourceGrids,
            sourceTracer: sourceTracer
        ).buildTracedInfoList()
    }
}

class SemanticMapTracer {
    private var sourceGrids: [CodeGrid]
    private var sourceTracer: TracingRoot
    
    private var matchedReferenceCache = [String: SemanticInfo]()
    private lazy var referenceableInfoCache = makeInfoCache()
    
    init(sourceGrids: [CodeGrid],
         sourceTracer: TracingRoot) {
        self.sourceGrids = sourceGrids
        self.sourceTracer = sourceTracer
    }
    
    private func buildTracedInfoList() {
        var tracedInfo = [TracedInfo]()
        
        for output in sourceTracer.logOutput.prefix(upTo: 10000) {
            switch findPossibleSemanticMatches(output).first {
            case .some(let first):
                tracedInfo.append(.found(out: output, info: first))
            default:
                tracedInfo.append(.missing(out: output))
            }
        }
        
        let results = tracedInfo.map { (check: TracedInfo) -> String in
            switch check {
            case let .missing(out):
                return "Missing \(out.callComponents.callPath)"
            case let .found(out, info):
                return "Found \(out.callComponents.callPath) -> \(info.referenceName)"
            }
        }
    }
        
    private func findPossibleSemanticMatches(
        _ output: TraceOutput
    ) -> [SemanticInfo] {
        let callPath = output.callComponents.callPath
        let callPathComponents = callPath.split(separator: ".").map { String($0) }
        var matches = [SemanticInfo]()
        for component in callPathComponents.reversed() {
            if component != callPathComponents.last {
                // Prefix components are all assumed structs / protocols(?) / classes
                if let found = firstSemanticInfoMatching(component) {
                    matches.append(found)
                }
            } else {
                // Last component is usually function or field update.
                if let found = firstSemanticInfoMatching(component) {
                    matches.append(found)
                }
            }
        }
        return matches
    }
    
    private func firstSemanticInfoMatching(
        _ callStackName: String
    ) -> SemanticInfo? {
        if let cached = matchedReferenceCache[callStackName] { return cached }
        
//        referenceableInfoCache.forEach { tuple in
//            tuple.info.forEach { semanticInfo in
//                print(semanticInfo.callStackName)
//            }
//        }
        
        for filtered in referenceableInfoCache {
            if let firstMatch = filtered.info.first(where: { $0.callStackName == callStackName }) {
                matchedReferenceCache[callStackName] = firstMatch
                return firstMatch
            }
        }
        
        return nil
    }
    
    private func makeInfoCache() -> [(grid: CodeGrid, info: [SemanticInfo])] {
        sourceGrids.map { grid in
            let filtered = grid.codeGridSemanticInfo
                .semanticsLookupBySyntaxId
                .values
                .filter { !$0.callStackName.isEmpty }
            return (grid, filtered)
        }
    }
}
