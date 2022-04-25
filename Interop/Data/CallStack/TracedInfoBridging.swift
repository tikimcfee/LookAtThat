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
}
#endif

typealias TraceValue = (grid: CodeGrid, info: SemanticInfo)

enum MatchedTraceOutput {
    case missing(
        out: TraceOutput,
        threadName: String,
        queueName: String,
        stamp: String = UUID().uuidString
    )
    
    case found(
        out: TraceOutput,
        trace: TraceValue,
        threadName: String,
        queueName: String,
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
        case let .missing(out, _, _, _): return out
        case let .found(out, _, _, _, _): return out
        }
    }
    
    var stamp: Self.ID {
        switch self {
        case let .missing(_, _, _, stamp): return stamp
        case let .found(_, _, _, stamp, _): return stamp
        }
    }
    
    var thread: String {
        switch self {
        case let .missing(_, thread, _, _): return thread
        case let .found(_, _, thread, _, _): return thread
        }
    }
    
    var maybeTrace: TraceValue? {
        switch self {
        case let .found(_, trace, _, _, _): return trace
        default: return nil
        }
    }
    
    var maybeFoundInfo: SemanticInfo? {
        switch self {
        case let .found(_, trace, _, _, _): return trace.info
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
    
    var isEntry: Bool {
        switch self {
        case .entry: return true
        case .exit:  return false
        }
    }
    
    var isExit: Bool {
        switch self {
        case .entry: return false
        case .exit:  return true
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
    
    #if TARGETING_SUI
    static var randomInvoke: String { "" }
    #else
    static var randomInvoke: SwiftTrace.Swizzle.Invocation { .current }
    #endif
    
    static var random: TraceOutput {
        switch Bool.random() {
        case true:
            return .entry(invocation: randomInvoke, method: nil, decorated: "helloWorld()", subLog: Bool.random())
        case false:
            return .exit(invocation: randomInvoke, method: nil, decorated: "peaceWorld()", subLog: Bool.random())
        }
    }
}
