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
        threadName: String
    )
    
    case found(
        out: TraceOutput,
        trace: TraceValue,
        threadName: String
    )
}

extension TracedInfo {
    var out: TraceOutput {
        switch self {
        case .missing(let out, _): return out
        case .found(let out, _, _): return out
        }
    }
    
    var thread: String {
        switch self {
        case .missing(_, let thread): return thread
        case .found(_, _, let thread): return thread
        }
    }
    
    var maybeTrace: TraceValue? {
        switch self {
        case .found(_, let trace, _): return trace
        default: return nil
        }
    }
    
    var maybeFoundInfo: SemanticInfo? {
        switch self {
        case .found(_, let trace, _): return trace.info
        default: return nil
        }
    }
}
