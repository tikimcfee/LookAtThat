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
            
        case let type where isToken(type):
            return .token(node, node.name ?? "")
            
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
    
    func searchUp<T>(
        from root: SCNNode,
        _ inclueRoot: Bool = true,
        _ action: (SCNNode, String, UnsafeMutablePointer<Bool>) -> T?
    ) -> T? {
        var stop: Bool = false
        if inclueRoot {
            if let result = action(root, root.name ?? "", &stop) {
                return result
            }
        }
        
        var parent: SCNNode? = root.parent
        while let nextParent = parent, !stop {
            if let result = action(nextParent, nextParent.name ?? "", &stop) {
                return result
            }
            parent = nextParent.parent
        }
        
        return nil
    }
    
    func extractHierarchyGrid(_ node: SCNNode) -> Result? {
        return searchUp(from: node) { node, name, stop in
            if let grid = maybeGetGrid(name) {
                return .grid(grid.source)
            } else {
                return nil
            }
        }
    }
    
    func extractGrid(_ node: SCNNode) -> Result? {
        return searchUp(from: node) { node, name, stop in
            if let grid = maybeGetGrid(name) {
                return .grid(grid.source)
            } else {
                return nil
            }
        }
    }

    func extraFocus(_ node: SCNNode) -> Result? {
        return searchUp(from: node) { node, name, stop in
            if let focus = maybeGetFocus(name) {
                return .focusBox(focus)
            } else {
                return nil
            }
        }
    }
}

private extension HitTestEvaluator {
    static let gridChildren = [
        HitTestType.codeGridSnapshot.rawValue,
        HitTestType.codeGridGlyphs.rawValue,
        HitTestType.semanticTab.rawValue
    ]
    
    func isToken(_ mask: Int) -> Bool {
        return HitTestType.codeGridToken.rawValue == mask
    }
    
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
}

extension HitTestEvaluator {
    enum Result {
        case grid(CodeGrid)
        case focusBox(FocusBox)
        case token(SCNNode, String)
        case unknown(SCNNode)
        
        var positionNode: SCNNode {
            switch self {
            case .grid(let codeGrid):
                return codeGrid.rootNode
            case .focusBox(let focusBox):
                return focusBox.rootNode
            case .token(let scnNode, _):
                return scnNode
            case .unknown(let scnNode):
                return scnNode
            }
        }
        
        func maybeValue<T>() -> T? {
            switch self {
            case .grid(let codeGrid):
                return codeGrid as? T
            case .focusBox(let focusBox):
                return focusBox as? T
            case .unknown(let scnNode):
                return scnNode as? T
            case .token(let scnNode, _):
                return scnNode as? T
            }
        }

        var defaultSortOrder: Int {
            switch self {
            case .grid:
                return 0
            case .focusBox:
                return 2
            case .token:
                return 3
            case .unknown:
                return 4
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
    static let codeGridFocusControl = HitTestType(rawValue: 1 << 13)
    
    static let all: HitTestType = [
        .codeSheet, .semanticTab, .rootCodeSheet,
        .directoryGroup, .codeGrid, .codeGridToken,
        .codeGridSnapshot, .codeGridGlyphs, .codeGridBlitter,
        .codeGridControl, .codeGridFocusBox, .codeGridFocusControl
    ]
    
    static let gridsAndTokens: HitTestType = [
        .codeGridToken, .codeGrid
    ]
}
