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
    case missing(out: TraceOutput)
    case found(out: TraceOutput, trace: TraceValue)
    
    var maybeTrace: TraceValue? {
        switch self {
        case .found(_, let trace): return trace
        default: return nil
        }
    }
    
    var maybeFoundInfo: SemanticInfo? {
        switch self {
        case .found(_, let trace): return trace.info
        default: return nil
        }
    }
}
