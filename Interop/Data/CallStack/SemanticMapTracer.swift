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
    static func start(
        sourceGrids: [CodeGrid],
        sourceTracer: TracingRoot
    ) -> [MatchedTraceOutput] {
        SemanticMapTracer(
            sourceGrids: sourceGrids,
            sourceTracer: sourceTracer
        ).buildTracedInfoList()
    }
    
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

extension SemanticMapTracer {
    func lookupInfo(_ trace: (TraceOutput, String)) -> MatchedTraceOutput? {
        if let firstMatch = findPossibleSemanticMatches(trace.0).first {
            return .found(
                out: trace.0,
                trace: firstMatch,
                threadName: trace.1
            )
        }
        return nil
    }
}

extension SemanticMapTracer {
    private func buildTracedInfoList() -> [MatchedTraceOutput] {
        var tracedInfo = [MatchedTraceOutput]()
        tracedInfo.reserveCapacity(sourceTracer.logOutput.count)
        
        for output in sourceTracer.logOutput.values {
            switch findPossibleSemanticMatches(output.0).first {
            case .some(let first):
                tracedInfo.append(.found(
                    out: output.0,
                    trace: first,
                    threadName: output.1
                ))
            default:
                //                tracedInfo.append(.missing(out: output))
                break
            }
        }
        
        return tracedInfo
    }
    
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
