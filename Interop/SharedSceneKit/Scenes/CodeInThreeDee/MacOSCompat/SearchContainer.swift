//
//  SearchContainer.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 12/5/21.
//

import Foundation
import SceneKit

class SearchContainer {
    var hovers = TokenHoverInteractionTracker()
    var codeGridFocus: CodeGridFocusController
    var codeGridParser: CodeGridParser
    
    init(codeGridParser: CodeGridParser,
         codeGridFocus: CodeGridFocusController) {
        self.codeGridParser = codeGridParser
        self.codeGridFocus = codeGridFocus
    }
    
    func createNewSearchFocus(_ state: SceneState) {
        print("creating new search focus")
        codeGridFocus.setNewFocus()
    }
    
    func search(_ newInput: String, _ state: SceneState) {
        print("new search ---------------------- [\(newInput)]")
        var toAdd: [CodeGrid] = []
        var toRemove: [CodeGrid] = []
        var toHover: Set<SCNNode> = []
        
        codeGridParser.query.walkGridsForSearch(
            newInput,
            onPositive: { foundInGrid, leafInfo in
                leafInfo.forEach { info in
                    foundInGrid.codeGridSemanticInfo.forAllNodesAssociatedWith(info.syntaxId, codeGridParser.tokenCache) { info, nodes in
                        toHover.formUnion(nodes)
                    }
                }
                toAdd.append(foundInGrid)
            },
            onNegative: { excludedGrid, leafInfo in
                toRemove.append(excludedGrid)
            }
        )
        sceneTransaction {
            toRemove.forEach {
                codeGridFocus.removeGridFromFocus($0)
            }
            toAdd.enumerated().forEach {
                codeGridFocus.addGridToFocus($0.element, $0.offset)
            }
            hovers.newSetHovered(toHover)
        }
        print("----------------------")
    }
}
