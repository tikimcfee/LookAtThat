//
//  MatchedTraceValue.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 4/29/22.
//

import Foundation

typealias TraceValue = (grid: CodeGrid, info: SemanticInfo)

protocol CallStateSource {
    var out: TraceLine { get }
    var queueName: String { get }
    var threadName: String { get }
    var callPath: String { get }
}

extension CallStateSource {
    var queueName: String { out.queueName }
    var threadName: String { out.threadName }
    var callPath: String { out.callPath }
}

enum MatchedTraceOutput {
    case missing(Missing)
    case found(Found)
    
    struct Missing: CallStateSource {
        let out: TraceLine
        let stamp: String = UUID().uuidString
    }
    
    struct Found: CallStateSource {
        let out: TraceLine
        let trace: TraceValue
        let stamp: String = UUID().uuidString
    }
}

extension MatchedTraceOutput: Identifiable, Hashable {
    var id: String { stamp }
    
    static func == (lhs: MatchedTraceOutput, rhs: MatchedTraceOutput) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension MatchedTraceOutput {
    var out: TraceLine {
        switch self {
        case let .missing(missing): return missing.out
        case let .found(found): return found.out
        }
    }
    
    var stamp: Self.ID {
        switch self {
        case let .missing(missing): return missing.stamp
        case let .found(found): return found.stamp
        }
    }
    
    var thread: String {
        switch self {
        case let .missing(missing): return missing.out.threadName
        case let .found(found): return found.out.threadName
        }
    }
    
    var queue: String {
        switch self {
        case let .missing(missing): return missing.out.queueName
        case let .found(found): return found.out.queueName
        }
    }
    
    var maybeTrace: TraceValue? {
        switch self {
        case let .found(found): return found.trace
        default: return nil
        }
    }
    
    var maybeFoundInfo: SemanticInfo? {
        switch self {
        case let .found(found): return found.trace.info
        default: return nil
        }
    }
}
