//
//  HitTestEvaluator.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 12/17/21.
//

import Foundation
import SceneKit

class HitTestEvaluator {
    
    let controller: CodePagesController
    private var parser: CodeGridParser { controller.codeGridParser }
    lazy var compat = controller.compat
    
    init(controller: CodePagesController) {
        self.controller = controller
    }
    
    func evaluate(_ hitTestResults: [SCNHitTestResult]) -> [Result] {
        hitTestResults.reduce(into: [Result]()) { allResults, hitTest in
            allResults.append(evaluateSingle(hitTest))
        }
    }
    
    func testAndEval(_ location: CGPoint, _ options: HitTestType) -> [Result] {
        let results = controller.sceneView.hitTest(location: location, options)
        return evaluate(results)
    }
    
    private func evaluateSingle(_ hitTest: SCNHitTestResult) -> Result {
        let node = hitTest.node
        switch node.categoryBitMask {
            
        case let type where isGridHierarchy(type):
            return safeExtract(node, extractHierarchyGrid(_:))
            
        case let type where isGrid(type):
            return safeExtract(node, extractGrid(_:))

        case let type where isFocus(type):
            return safeExtract(node, extraFocus(_:))

        default:
            return .unknown(node)
        }
    }
}

private extension HitTestEvaluator {
    func safeExtract(_ node: SCNNode, _ extractor: (SCNNode) -> Result?) -> Result {
        return extractor(node) ?? .unknown(node)
    }
    
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

    func extraFocus(_ node: SCNNode) -> Result? {
        guard let focusRootNode = node.parent,
              let focusRootId = focusRootNode.name,
              let cachedFocus = maybeGetFocus(focusRootId)
        else {
            return nil
        }
        
        return .focusBox(cachedFocus)
    }
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
    
    func maybeGetFocus(_ id: FocusBox.ID) -> FocusBox? {
        return compat.inputCompat.focus.focusCache.maybeGet(id)
    }
}

extension HitTestEvaluator {
    enum Result {
        case grid(CodeGrid)
        case unknown(SCNNode)
        case focusBox(FocusBox)
        
        var positionNode: SCNNode {
            switch self {
            case .grid(let codeGrid):
                return codeGrid.rootNode
            case .unknown(let sCNNode):
                return sCNNode
            case .focusBox(let focusBox):
                return focusBox.rootNode
            }
        }

        var defaultSortOrder: Int {
            switch self {
            case .grid:
                return 0
            case .focusBox:
                return 1
            case .unknown:
                return 2
            }
        }
        
    }
}
