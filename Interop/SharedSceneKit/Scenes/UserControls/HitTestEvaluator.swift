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
            
        case let type where isControl(type):
            return safeExtract(node, extractControl(_:))

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
    
    func extractControl(_ node: SCNNode) -> Result? {
        guard let controlRootNode = node.parent,
              let controlNodeId = controlRootNode.name,
              let cachedCotrol = maybeGetControl(controlNodeId)
        else {
            return nil
        }
        
        return .control(cachedCotrol)
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
    
    func isControl(_ mask: Int) -> Bool {
        return HitTestType.codeGridControl.rawValue == mask
    }
}

private extension HitTestEvaluator {
    func maybeGetGrid(_ id: CodeGrid.ID) -> (source: CodeGrid, clone: CodeGrid)? {
        return parser.gridCache.cachedGrids[id]
    }
    
    func maybeGetFocus(_ id: FocusBox.ID) -> FocusBox? {
        return compat.inputCompat.focus.focusCache.maybeGet(id)
    }
    
    func maybeGetControl(_ id: CodeGrid.ID) -> CodeGridControl? {
        return parser.gridCache.cachedControls[id]
    }
}

extension HitTestEvaluator {
    enum Result {
        case grid(CodeGrid)
        case focusBox(FocusBox)
        case control(CodeGridControl)
        case unknown(SCNNode)
        
        var positionNode: SCNNode {
            switch self {
            case .grid(let codeGrid):
                return codeGrid.rootNode
            case .focusBox(let focusBox):
                return focusBox.rootNode
            case .control(let control):
                return control.displayGrid.rootNode
            case .unknown(let sCNNode):
                return sCNNode
            }
        }
        
        func maybeValue<T>() -> T? {
            switch self {
            case .grid(let codeGrid):
                return codeGrid as? T
            case .focusBox(let focusBox):
                return focusBox as? T
            case .control(let control):
                return control as? T
            case .unknown(let sCNNode):
                return sCNNode as? T
            }
        }

        var defaultSortOrder: Int {
            switch self {
            case .grid:
                return 0
            case .control:
                return 1
            case .focusBox:
                return 2
            case .unknown:
                return 3
            }
        }
    }
}


struct HitTestType: OptionSet {
    let rawValue: Int
    
    static let codeSheet        = HitTestType(rawValue: 1 << 2)
    static let rootCodeSheet    = HitTestType(rawValue: 1 << 3)
    static let semanticTab      = HitTestType(rawValue: 1 << 4)
    static let directoryGroup   = HitTestType(rawValue: 1 << 5)
    static let codeGrid         = HitTestType(rawValue: 1 << 6)
    static let codeGridToken    = HitTestType(rawValue: 1 << 7)
    static let codeGridSnapshot = HitTestType(rawValue: 1 << 8)
    static let codeGridGlyphs   = HitTestType(rawValue: 1 << 9)
    static let codeGridBlitter  = HitTestType(rawValue: 1 << 10)
    static let codeGridControl  = HitTestType(rawValue: 1 << 11)
    static let codeGridFocusBox = HitTestType(rawValue: 1 << 12)
    
    static let all: HitTestType = [
        .codeSheet, .semanticTab, .rootCodeSheet,
        .directoryGroup, .codeGrid, .codeGridToken,
        .codeGridSnapshot, .codeGridGlyphs, .codeGridBlitter,
        .codeGridControl, .codeGridFocusBox
    ]
    
    static let gridsAndTokens: HitTestType = [
        .codeGridToken, .codeGrid
    ]
}
