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
    var hoveredToken: String? {
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
    
    private lazy var hoverEval = HitTestEvaluator(controller: controller)
    private func doCodeGridHover(_ point: CGPoint) {
        var (tokenSet, grid): (CodeGridNodes?, CodeGrid?)
        let results = hoverEval.testAndEval(point, [.gridsAndTokens])
        
        for hitTest in results where tokenSet == nil || grid == nil {
            switch hitTest {
            case let .token(_, name):
                guard tokenSet == nil else { continue }
                let hovered = codeGridParser.tokenCache[name]
                tokenSet = hovered
                self.hoveredToken = name
                if !hovered.isEmpty {
                    touchState.mouse.hoverTracker.newSetHovered(hovered)
                    self.hoveredToken = hoveredToken
                }
                
            case let .grid(foundGrid):
                guard grid == nil else { continue }
                grid = foundGrid
                self.hoveredInfo = foundGrid.codeGridSemanticInfo
                self.hoveredGrid = foundGrid
                
            default:
                print("skip: \(hitTest)")
            }
        }
    }
}
