//
//  CodeGridSelectionController.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 9/30/22.
//

import Foundation
import MetalLink
import BitHandling

import SwiftSyntax // Needed: tracks selection

@inline(__always)
func UpdateNode(
    _ node: GlyphNode,
    in grid: CodeGrid,
    _ action: (inout GlyphConstants) -> Void
) {
    let pointer = grid.rootNode.instanceState.rawPointer
    guard let index = node.meta.instanceBufferIndex else {
        return
    }
    action(&pointer[index])
}

class GlobalNodeController {
    func focus(_ node: GlyphNode, in grid: CodeGrid) {
        UpdateNode(node, in: grid) {
            $0.modelMatrix.translate(vector: LFloat3(0, 0, 8))
            $0.addedColor += LFloat4(0.05, 0.09, 0.09, 1)
        }
    }
    
    func unfocus(_ node: GlyphNode, in grid: CodeGrid) {
        UpdateNode(node, in: grid) {
            $0.modelMatrix.translate(vector: LFloat3(0, 0, -8))
            $0.addedColor -= LFloat4(0.05, 0.09, 0.09, 1)
        }
    }
}

class CodeGridSelectionController: ObservableObject {
    struct State {
        var trackedGridSelections = [CodeGrid: Set<SyntaxIdentifier>]()
        var trackedMapSelections = Set<SyntaxIdentifier>()
        
        func isSelected(_ id: SyntaxIdentifier) -> Bool {
            trackedMapSelections.contains(id)
            || trackedGridSelections.values.contains(where: { $0.contains(id) })
        }
    }
    
    @Published var state: State = State()
    var tokenCache: CodeGridTokenCache
    var nodeController: GlobalNodeController = GlobalNodeController()
    
    init(
        tokenCache: CodeGridTokenCache
    ) {
        self.tokenCache = tokenCache
    }
    
    func selected(
        id: SyntaxIdentifier,
        in grid: CodeGrid
    ) {
        // Update set first
        var selectionSet = state.trackedGridSelections[grid, default: []]
        let isSelectedAfterToggle = selectionSet.toggle(id) == .addedToSet
        state.trackedGridSelections[grid] = selectionSet
        
        let update = isSelectedAfterToggle
            ? nodeController.focus(_: in:)
            : nodeController.unfocus(_: in:)
        
        grid.semanticInfoMap
            .walkFlattened(from: id, in: tokenCache) { info, nodes in
                for node in nodes {
                    update(node, grid)
                }
            }
    }
    
    func isSelected(_ id: SyntaxIdentifier) -> Bool {
        return state.isSelected(id)
    }
}
