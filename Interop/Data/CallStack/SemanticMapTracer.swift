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
    
    private var matchedReferenceCache = [String: [TraceValue]]() // v2
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
    func lookupInfo(_ tuple: ThreadStorageTuple) -> MatchedTraceOutput {
        if let firstMatch = findPossibleSemanticMatches(tuple.out).last {
            //        if let firstMatch = findPossibleSemanticMatches(tuple.out).first { // v2
            return .found(.init(
                out: tuple.out,
                trace: firstMatch,
                threadName: tuple.thread.threadName,
                queueName: tuple.queueName
            ))
        } else {
            return .missing(.init(
                out: tuple.out,
                threadName: tuple.thread.threadName,
                queueName: tuple.queueName
            ))
        }
    }
}

//MARK: - Lookup v3

private typealias CacheType = [CodeGrid: [String: Set<SemanticInfo>]]

extension SemanticMapTracer {
    private func makeInfoCache() -> CacheType {
        sourceGrids.reduce(into: CacheType()) { result, sourceGrid in
            result[sourceGrid] = sourceGrid.semanticInfoBuilder.localCallStackCache
        }
    }
    
    private func findPossibleSemanticMatches(
        _ output: TraceOutput
    ) -> [TraceValue] {
        let (callPath, allComponents) = output.callComponents
        if let cachedResult = matchedReferenceCache[callPath] {
            print("_CACHED: \(callPath) (\(cachedResult.count)")
            return cachedResult
        }
        
        print("ON:\t\(callPath)\t\(allComponents)")
        
        var matches = [TraceValue]()
        var currentGrids = referenceableInfoCache
        var didReduce = false
        for component in allComponents {
            print("\tCHECK: \(component)")
            let rereduce = gridsMatching(component, currentGrids)
            print("\tRereduce has: \(rereduce.count)")
            didReduce = didReduce || rereduce.count > 0
            if component == "CodeGrid" {
                print("welcome to my nightmare")
            }
            currentGrids = rereduce.count > 0 ? rereduce : currentGrids
        }
        
        if !didReduce {
            print("Nothing found for \(callPath), skipping matches")
            return matches
        }
        
        print("Found candidate grids: \(currentGrids.count)")
        for (grid, gridLocalLookup) in currentGrids {
            print("Found candidate info on \(grid.id)); final filter")
            
            for expectedComponent in allComponents {
                guard let matchingInfoSet = gridLocalLookup[expectedComponent] else {
                    print("Found candidate missing \(expectedComponent) -> \(grid.fileName)")
                    continue
                }
                
                for match in matchingInfoSet {
                    guard expectedComponent == match.callStackName else {
                        print("Found candidate skipping \(expectedComponent)!=\(match.callStackName)")
                        continue
                    }
                    matches.append((grid, match))
                }
            }
        }
        
        matchedReferenceCache[callPath] = matches
        return matches
    }
    
    private func gridsMatching(_ searchComponent: String, _ source: CacheType) -> CacheType {
        var reducedInfo = CacheType()
        for (grid, callStackDictionary) in source {
            if let _ = callStackDictionary[searchComponent] {
                print("\t\tFound '\(searchComponent)' --> \(grid.fileName)")
                reducedInfo[grid] = grid.semanticInfoBuilder.localCallStackCache
            }
        }
        return reducedInfo
    }
}
