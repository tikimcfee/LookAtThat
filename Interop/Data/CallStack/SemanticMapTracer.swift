//
//  SemanticMapTracer.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 4/23/22.
//

import Foundation

#if !TARGETING_SUI
import SwiftTrace
#endif

class SemanticMapTracer {
    private var sourceGrids: [CodeGrid]
    private var sourceTracer: TracingRoot
    
    private var matchedReferenceCache = [String: TraceValue]()
    private lazy var referenceableInfoCache = makeInfoCache()
    
    private init(sourceGrids: [CodeGrid],
                 sourceTracer: TracingRoot) {
        self.sourceGrids = sourceGrids
        self.sourceTracer = sourceTracer
    }
}

extension SemanticMapTracer {
    static func wrapForLazyLoad(
        sourceGrids: [CodeGrid],
        sourceTracer: TracingRoot
    ) -> SemanticMapTracer  {
        SemanticMapTracer(
            sourceGrids: sourceGrids,
            sourceTracer: sourceTracer
        )
    }
}

class ThreadInfoExtract {
    static let rawInfoRegex = #"\{(.*), (.*)\}"#
    static let infoRegex = try! NSRegularExpression(pattern: rawInfoRegex)
    private init() {}
    static func from(_ string: String) -> (number: String, name: String) {
        let range = NSRange(string.range(of: string)!, in: string)
        let matches = Self.infoRegex.matches(in: string, range: range)
        
        for match in matches {
            let maybeNumber = Range(match.range(at: 1), in: string).map { string[$0] } ?? ""
            let maybeName = Range(match.range(at: 2), in: string).map { string[$0] } ?? ""
            return (String(maybeNumber), String(maybeName))
        }
        return ("", "")
    }
}

extension SemanticMapTracer {
    func lookupInfo(_ trace: (TraceOutput, Thread)) -> MatchedTraceOutput? {
        if let firstMatch = findPossibleSemanticMatches(trace.0).first {
            return .found(
                out: trace.0,
                trace: firstMatch,
                threadName: ThreadInfoExtract.from(trace.1.description).number
            )
        }
        return nil
    }
}

extension SemanticMapTracer {
    private func findPossibleSemanticMatches(
        _ output: TraceOutput
    ) -> [TraceValue] {
        let callPath = output.callComponents.callPath
        let callPathComponents = callPath.split(separator: ".").map { String($0) }
        var matches = [TraceValue]()
        
        for component in callPathComponents.reversed() {
            if let found = firstSemanticInfoMatching(component) {
                matches.append(found)
            }
        }
        
        return matches
    }
    
    private func firstSemanticInfoMatching(
        _ callStackName: String
    ) -> TraceValue? {
        if let cached = matchedReferenceCache[callStackName] { return cached }
        
        // print out all callstack names, see what was found
        //        referenceableInfoCache.forEach { tuple in
        //            tuple.info.forEach { semanticInfo in
        //                print(semanticInfo.callStackName)
        //            }
        //        }
        
        for filtered in referenceableInfoCache {
            if let firstMatch = filtered.info.first(where: { $0.callStackName == callStackName }) {
                matchedReferenceCache[callStackName] = (filtered.grid, firstMatch)
                return (filtered.grid, firstMatch)
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
