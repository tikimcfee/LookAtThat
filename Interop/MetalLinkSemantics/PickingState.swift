//
//  PickingState.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 10/18/22.
//

import Foundation
import SwiftSyntax

struct NodePickingState {
    let targetGrid: CodeGrid
    let nodeID: InstanceIDType
    let node: GlyphNode
    
    var nodeBufferIndex: Int? { node.meta.instanceBufferIndex }
    var nodeSyntaxID: NodeSyntaxID? { node.meta.syntaxID }
    
    var constantsPointer: ConstantsPointer {
        return targetGrid.rootNode.instanceState.rawPointer
    }
    
    var parserSyntaxID: SyntaxIdentifier? {
        guard let id = nodeSyntaxID else { return nil }
        return targetGrid.semanticInfoMap.syntaxIDLookupByNodeId[id]
    }
    
    enum Event {
        case initial
        case useLast(last: NodePickingState?)
        case matchesLast(last: NodePickingState, new: NodePickingState)
        case foundNew(last: NodePickingState?, new: NodePickingState)
        
        var latestState: NodePickingState? {
            switch self {
            case let .useLast(.some(state)),
                let .matchesLast(_, state),
                let .foundNew(_, state):
                return state
            default:
                return nil
            }
        }
    }
}

struct GridPickingState {
    let targetGrid: CodeGrid
    
    enum Event {
        case initial
        case useLast(last: GridPickingState?)
        case matchesLast(last: GridPickingState, new: GridPickingState)
        case foundNew(last: GridPickingState?, new: GridPickingState)
        
        var latestState: GridPickingState? {
            switch self {
            case let .useLast(.some(state)),
                let .matchesLast(_, state),
                let .foundNew(_, state):
                return state
            default:
                return nil
            }
        }
    }
}
