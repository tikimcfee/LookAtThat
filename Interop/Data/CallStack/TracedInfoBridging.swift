//
//  TracedInfoBridging.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 4/23/22.
//

import Foundation

#if !TARGETING_SUI
import SwiftTrace
#else
enum TraceOutput {
    case entry(invocation: String, method: Method?, decorated: String, subLog: Bool)
    case exit (invocation: String, method: Method?, decorated: String, subLog: Bool)
    public var decorated: String {
        switch self {
        case .entry(_, _, let decorated, _): return decorated
        case .exit(_, _, let decorated, _): return decorated
        }
    }
    
    static var random: TraceOutput {
        switch Bool.random() {
        case true:
            return .entry(invocation: "Invocation \(Int.random(in: 0...100))", method: nil, decorated: "helloWorld()", subLog: Bool.random())
        case false:
            return .exit(invocation: "Invocation_X \(Int.random(in: 100...200))", method: nil, decorated: "peaceWorld()", subLog: Bool.random())
        }
    }
}
#endif

typealias TraceValue = (grid: CodeGrid, info: SemanticInfo)

enum MatchedTraceOutput {
    case missing(
        out: TraceOutput,
        threadName: String,
        stamp: String = UUID().uuidString
    )
    
    case found(
        out: TraceOutput,
        trace: TraceValue,
        threadName: String,
        stamp: String = UUID().uuidString
    )
}

extension MatchedTraceOutput: Identifiable, Hashable {
    static func == (lhs: MatchedTraceOutput, rhs: MatchedTraceOutput) -> Bool {
        lhs.id == rhs.id
    }
    
    var id: String { stamp }
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
}

extension MatchedTraceOutput {
    var out: TraceOutput {
        switch self {
        case let .missing(out, _, _): return out
        case let .found(out, _, _, _): return out
        }
    }
    
    var stamp: Self.ID {
        switch self {
        case let .missing(_, _, stamp): return stamp
        case let .found(_, _, _, stamp): return stamp
        }
    }
    
    var thread: String {
        switch self {
        case let .missing(_, thread, _): return thread
        case let .found(_, _, thread, _): return thread
        }
    }
    
    var maybeTrace: TraceValue? {
        switch self {
        case let .found(_, trace, _, _): return trace
        default: return nil
        }
    }
    
    var maybeFoundInfo: SemanticInfo? {
        switch self {
        case let .found(_, trace, _, _): return trace.info
        default: return nil
        }
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
