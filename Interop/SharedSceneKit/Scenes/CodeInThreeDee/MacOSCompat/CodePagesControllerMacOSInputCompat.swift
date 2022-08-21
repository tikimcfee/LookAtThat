//
//  InputCompat.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 12/17/21.
//

import Foundation
import SceneKit

class CodePagesControllerMacOSInputCompat {
    let controller: CodePagesController
    
    lazy var searchController = {
        SearchContainer(codeGridParser: codeGridParser,
                        codeGridFocus: focus)
    }()
    
    lazy var focus: CodeGridFocusController = {
        let focus = CodeGridFocusController(
            controller: controller
        )
        return focus
    }()
    
    private lazy var hitTestEval = HitTestEvaluator(controller: controller)
    
    init(controller: CodePagesController) {
        self.controller = controller
    }
    
    var touchState: TouchState { controller.touchState }
    var sceneCameraNode: SCNNode { controller.sceneCameraNode }
    var sceneView: SCNView { controller.sceneView }
    var codeGridParser: CodeGridParser { controller.codeGridParser }
    var keyboardInterceptor: KeyboardInterceptor { controller.compat.keyboardInterceptor }
    
    static let scrollSensitivity = CGFloat(5.0)
    
    func newScrollEvent(_ event: NSEvent) {
        let sensitivity = Self.scrollSensitivity
        let scaledX = -event.deltaX * sensitivity
        let scaledY = event.deltaY * sensitivity
        
        moveCamera(scaledX: scaledX, scaledY: scaledY, event)
        keyboardInterceptor.onNewKeyEvent(event)
    }
    
    private func moveCamera(scaledX: CGFloat, scaledY: CGFloat, _ event: NSEvent? = nil) {
        let targetNode: SCNNode
        var moveVertically = false
        
        if let hoveredSheet = touchState.mouse.currentHoveredSheet,
           event?.modifierFlags.contains(.control) == true {
            targetNode = hoveredSheet
        } else if event?.modifierFlags.contains(.shift) == true {
            targetNode = sceneCameraNode
            moveVertically = true
        } else {
            targetNode = sceneCameraNode
        }
        
        sceneTransaction(0.0835, .easeOut) {
            targetNode.simdPosition += targetNode.simdWorldRight * Float(scaledX)
            if moveVertically {
                targetNode.simdPosition += targetNode.simdWorldUp * Float(scaledY)
            } else {
                targetNode.simdPosition += targetNode.simdWorldFront * -Float(scaledY)
            }
        }
    }
    
    func newMouseDown(_ event: NSEvent) {
        DispatchQueue.main.async { doClick() }
        func doClick() {
            let point = sceneView.convert(event.locationInWindow, to: nil)
            let newMockEvent = GestureEvent(
                state: .began,
                type: .deviceTap,
                currentLocation: point,
                commandStart: nil,
                optionStart: nil,
                controlStart: nil
            )
            controller.panGestureShim.onTap(newMockEvent)
        }
    }
    
    func newMouseUp(_ event: NSEvent) {
        DispatchQueue.main.async { doClick() }
        func doClick() {
            let point = sceneView.convert(event.locationInWindow, to: nil)
            let newMockEvent = GestureEvent(
                state: .ended,
                type: .deviceTap,
                currentLocation: point,
                commandStart: nil,
                optionStart: nil,
                controlStart: nil
            )
            controller.panGestureShim.onTap(newMockEvent)
        }
    }
    
    func newKeyEvent(_ event: NSEvent) {
        keyboardInterceptor.onNewKeyEvent(event)
    }
    
    func newMousePosition(_ event: OSEvent) {
        // this should be a single walk with a switch that handles the node each time. this is slow otherwise, lots of
        // O(M * N) operations on each position update which is Woof.
        doCodeGridHover(event.locationInWindow)
    }
    
    func doNewSearch(
        _ newInput: String,
        _ state: SceneState,
        _ completion: @escaping () -> Void
    ) {
        searchController.search(newInput, state, completion)
    }
    
    private func doCodeGridHover(_ point: CGPoint) {
        let results = hitTestEval.testAndEval(point, [.gridsAndTokens])
        
        // take first
        var (tokenNode, tokenName): (SCNNode?, String?)
        var grid: CodeGrid?
        var shouldContinue: Bool {
            grid == nil || tokenNode == nil || tokenName == nil
        }
        
        for hitTestResult in results where shouldContinue {
            switch hitTestResult {
            case let .token(node, name) where tokenNode == nil:
                tokenNode = node
                tokenName = name
            case let .grid(foundGrid) where grid == nil:
                grid = foundGrid
            default:
                break
            }
        }
        
        if let tokenNode = tokenNode, let tokenName = tokenName {
            onTokenHovered(tokenNode, tokenName)
        }
        
        if let grid = grid {
            onGridHovered(grid)
        }
    }
    
    private func onTokenHovered(_ node: SCNNode, _ name: String) {
        
        let hovered = codeGridParser.tokenCache[name]
        if !hovered.isEmpty {
            self.touchState.mouse.hoverTracker.newSetHovered(hovered)
            DispatchQueue.main.async {
                self.globalHoveredToken = name
            }
        }
        
        DispatchQueue.main.async {
            self.globalHoveredNode = node
        }
    }
    
    private func onGridHovered(_ grid: CodeGrid) {
        guard !grid.codeGridSemanticInfo.isEmpty else {
//            print("Skip grid hover: \(grid.id)")
            return
        }
        DispatchQueue.main.async {
            self.globalHoveredInfo = grid.codeGridSemanticInfo
            self.hoveredGrid = grid
        }
    }
}

extension CodePagesControllerMacOSInputCompat {
    private var globalHoveredGrid: CodeGrid? {
        get { CodePagesController.shared.hover.state.hoveredGrid }
        set { CodePagesController.shared.hover.state.hoveredGrid = newValue }
    }
    
    private var globalHoveredInfo: CodeGridSemanticMap {
        get { CodePagesController.shared.hover.state.hoveredInfo }
        set { CodePagesController.shared.hover.state.hoveredInfo = newValue }
    }
    
    private var globalHoveredToken: String? {
        get { CodePagesController.shared.hover.state.hoveredTokenId }
        set { CodePagesController.shared.hover.state.hoveredTokenId = newValue }
    }
    
    private var globalHoveredNode: SCNNode? {
        get { CodePagesController.shared.hover.state.hoveredNode }
        set { CodePagesController.shared.hover.state.hoveredNode = newValue }
    }
    
    var hoveredGrid: CodeGrid? {
        get { globalHoveredGrid }
        set {
            switch (globalHoveredGrid, newValue) {
            case let (.some(grid), .some(newGrid)) where newGrid.id == grid.id:
                //                print("Skipping grid set on hover, ids match: \(grid.id == newGrid.id)")
                break
                
            case let (.some(grid), .some(newGrid)):
                grid.swapOutRootGlyphs()
                globalHoveredGrid = newGrid
                newGrid.swapInRootGlyphs()
                
            case (.none, .none):
                globalHoveredGrid?.swapOutRootGlyphs()
                globalHoveredGrid = newValue
                
            case let (.some(grid), .none):
                grid.swapOutRootGlyphs()
                globalHoveredGrid = newValue
                
            case let (.none, .some(newGrid)):
                newGrid.swapInRootGlyphs()
                globalHoveredGrid = newGrid
            }
        }
    }
}
