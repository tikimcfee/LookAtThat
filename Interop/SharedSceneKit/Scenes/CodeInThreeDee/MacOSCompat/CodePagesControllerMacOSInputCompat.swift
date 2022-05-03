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
    
    var hoveredGrid: CodeGrid? {
        willSet {
            guard newValue?.id != hoveredGrid?.id else { return }
            hoveredGrid?.swapOutRootGlyphs()
            newValue?.swapInRootGlyphs()
        }
    }
    
    var hoveredInfo: CodeGridSemanticMap? {
        get { controller.hoveredInfo }
        set { controller.hoveredInfo = newValue }
    }
    var hoveredToken: String {
        get { controller.hoveredToken }
        set { controller.hoveredToken = newValue }
    }
    
    func newScrollEvent(_ event: NSEvent) {
        
        let sensitivity = CGFloat(1.5)
        let scaledX = -event.deltaX * sensitivity
        let scaledY = event.deltaY * sensitivity
        
        moveCamera(scaledX: scaledX, scaledY: scaledY, event)
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
        
        sceneTransaction(0) {
            targetNode.simdPosition += targetNode.simdWorldRight * Float(scaledX)
            if moveVertically {
                targetNode.simdPosition += targetNode.simdWorldUp * -Float(scaledY)
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
    
    func newKeyEvent(_ event: NSEvent) {
        keyboardInterceptor.onNewKeyEvent(event)
    }
    
    func newMousePosition(_ point: CGPoint) {
        // this should be a single walk with a switch that handles the node each time. this is slow otherwise, lots of
        // O(M * N) operations on each position update which is Woof.
        doCodeGridHover(point)
    }
    
    func doNewSearch(_ newInput: String, _ state: SceneState) {
        searchController.search(newInput, state)
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
            touchState.mouse.hoverTracker.newSetHovered(hovered)
            hoveredToken = name
        }
    }
    
    private func onGridHovered(_ grid: CodeGrid) {
        guard !grid.codeGridSemanticInfo.isEmpty else {
//            print("Skip grid hover: \(grid.id)")
            return
        }
        hoveredInfo = grid.codeGridSemanticInfo
        hoveredGrid = grid
    }
}
