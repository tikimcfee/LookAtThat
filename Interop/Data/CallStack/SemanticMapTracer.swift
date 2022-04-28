//
//  SemanticMapTracer.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 4/23/22.
//

import Foundation

#if !TARGETING_SUI
import SwiftTrace
import SwiftUI
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
    private static let INIT_SYNTHETIC = "__allocating_init"
    
    private static func findBestMatch(_ tuple: ThreadStorageTuple, _ source: [TraceValue]) -> TraceValue? {
        let allComponents = tuple.out.callComponents.allComponents
        
        // print(Array(repeating: "-", count: 10).joined())
        
        // print("Lookup found \(source.count) potential semantic matches")
        // print("Source: \(tuple.out.signature)")
        // print("Cmpnts: \(allComponents)")
//        for match in source {
            // print("\(match.info.callStackName) | \(match.info.referenceName) | \(match.grid.fileName)")
//        }
        
        if allComponents.last == INIT_SYNTHETIC {
            // print("Found <init>, finding first Class or Struct declaration")
            let initInfo: [TraceValue] = source.compactMap { grid, matchedInfo in
                let nodeType = grid.semanticInfoBuilder[matchedInfo.node]
                switch nodeType {
                case .classDecl, .structDecl:
                    return (grid, matchedInfo)
                default:
                    return nil
                }
            }
            // print("Found <init>, matches: \(initInfo.count)")
            // print("Taking: \(initInfo.first?.grid.fileName ?? "nil")")
            return initInfo.first
        }
        
        // print("No rule matching call stack, return last value")
        // print(Array(repeating: "-", count: 10).joined())
        
        return source.last
    }
    
    func lookupInfo(_ tuple: ThreadStorageTuple) -> MatchedTraceOutput {
        let allFoundMatches = findPossibleSemanticMatches(tuple.out)
        let bestMatch = Self.findBestMatch(tuple, allFoundMatches)
        
        if let firstMatch = bestMatch {
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
            // print("_CACHED: \(callPath) (\(cachedResult.count)")
            return cachedResult
        }
        
        // print("ON:\t\(callPath)\t\(allComponents)")
        
        var matches = [TraceValue]()
        var currentGrids = referenceableInfoCache
        var didReduce = false
        for component in allComponents {
            // print("\tCHECK: \(component)")
            let rereduce = gridsMatching(component, currentGrids)
            // print("\tRereduce has: \(rereduce.count)")
            didReduce = didReduce || rereduce.count > 0
            currentGrids = rereduce.count > 0 ? rereduce : currentGrids
        }
        
        if !didReduce {
            // print("Nothing found for \(callPath), skipping matches")
            return matches
        }
        
        // print("Found candidate grids: \(currentGrids.count)")
        for (grid, gridLocalLookup) in currentGrids {
            // print("Found candidate info on \(grid.id)); final filter")
            
            for expectedComponent in allComponents {
                guard let matchingInfoSet = gridLocalLookup[expectedComponent] else {
                    // print("Found candidate missing \(expectedComponent) -> \(grid.fileName)")
                    continue
                }
                
                for match in matchingInfoSet {
                    switch expectedComponent {
                    case match.callStackName:
                        // print("Found adding \(match.callStackName) -> \(grid.fileName) -> \(match.referenceName)")
                        matches.append((grid, match))
                        
                    default:
                        // print("Found candidate skipping \(expectedComponent)!=\(match.callStackName)")
                        break
                    }
                }
            }
        }
        
        // print("Total matches found: \(matches.count)")
        matchedReferenceCache[callPath] = matches
        return matches
    }
    
    private func gridsMatching(_ searchComponent: String, _ source: CacheType) -> CacheType {
        var reducedInfo = CacheType()
        for (grid, callStackDictionary) in source {
            if let _ = callStackDictionary[searchComponent] {
                // print("\t\tFound '\(searchComponent)' --> \(grid.fileName)")
                reducedInfo[grid] = grid.semanticInfoBuilder.localCallStackCache
            }
        }
        return reducedInfo
    }
}
