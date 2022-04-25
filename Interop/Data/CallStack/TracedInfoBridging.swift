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
struct TraceOutput {
    
}
#endif

typealias TraceValue = (grid: CodeGrid, info: SemanticInfo)

enum TracedInfo {
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

extension TracedInfo: Identifiable, Hashable {
    static func == (lhs: TracedInfo, rhs: TracedInfo) -> Bool {
        lhs.id == rhs.id
    }
    
    var id: String { stamp }
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
}

extension TracedInfo {
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
