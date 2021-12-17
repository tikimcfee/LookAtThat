//
//  HitTestEvaluator.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 12/17/21.
//

import Foundation
import SceneKit

private enum Result {
    case grid(CodeGrid)
    case focusBox(FocusBox)
}

class HitTestEvaluator {
    
    let controller: CodePagesController
    private var parser: CodeGridParser { controller.codeGridParser }

#if os(macOS)
    lazy var compat = controller.macosCompat
#endif
    
    init(controller: CodePagesController) {
        self.controller = controller
    }
    
    func evaluate(_ hitTestResults: [SCNHitTestResult]) {
        let found = hitTestResults.reduce(into: [Result]()) { allResults, hitTest in
            let node = hitTest.node
            
            switch node.categoryBitMask {
            case let type where isGridHierarchy(type):
                if let result = extractHierarchyGrid(node) {
                    allResults.append(result)
                }
                
                
            case let type where isGrid(type):
                if let result = extractGrid(node) {
                    allResults.append(result)
                }
#if os(macOS)
            case let type where isFocus(type):
                if let result = extraFocus(node) {
                    allResults.append(result)
                }
#endif
                
            default:
                break
            }
        }
    }
}

private extension HitTestEvaluator {
    func extractHierarchyGrid(_ node: SCNNode) -> Result? {
        guard let targetNodeParent = node.parent,
              let targetNodeRoot = targetNodeParent.parent,
              let gridNodeNameId = targetNodeRoot.name,
              let grid = maybeGetGrid(gridNodeNameId)
        else {
            return nil
        }
        
        return .grid(grid.source)
    }
    
    func extractGrid(_ node: SCNNode) -> Result? {
        guard let gridBackgroundNodeParent = node.parent,
              let rootNodeId = gridBackgroundNodeParent.name,
              let grid = maybeGetGrid(rootNodeId)
        else {
            return nil
        }
        
        return .grid(grid.source)
    }

#if os(macOS)
    func extraFocus(_ node: SCNNode) -> Result? {
        guard let focusRootNode = node.parent,
              let focusRootId = focusRootNode.name,
              let cachedFocus = maybeGetFocus(focusRootId)
        else {
            return nil
        }
        
        return .focusBox(cachedFocus)
    }
#endif
}

private extension HitTestEvaluator {
    static let gridChildren = Set([
        HitTestType.codeGridSnapshot.rawValue,
        HitTestType.codeGridGlyphs.rawValue,
        HitTestType.semanticTab.rawValue
    ])
    
    func isGridHierarchy(_ mask: Int) -> Bool {
        return Self.gridChildren.contains(mask)
    }
    
    func isGrid(_ mask: Int) -> Bool {
        return HitTestType.codeGrid.rawValue == mask
    }
    
    func isFocus(_ mask: Int) -> Bool {
        return HitTestType.codeGridFocusBox.rawValue == mask
    }
}

private extension HitTestEvaluator {
    func maybeGetGrid(_ id: CodeGrid.ID) -> (source: CodeGrid, clone: CodeGrid)? {
        return parser.gridCache.cachedGrids[id]
    }
    
#if os(macOS)
    func maybeGetFocus(_ id: FocusBox.ID) -> FocusBox? {
        return compat.inputCompat.focus.focusCache.maybeGet(id)
    }
#elseif os(iOS)
    
#endif
    
}


