//
//  CodePagesControllerMacOSCompat.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 11/25/21.
//

import Foundation
import SceneKit
import SwiftSyntax
import Combine
import FileKit

class CodePagesControllerMacOSCompat {
    let controller: CodePagesController
    let inputCompat: CodePagesControllerMacOSInputCompat
    
    init(controller: CodePagesController) {
        self.controller = controller
        self.inputCompat = CodePagesControllerMacOSInputCompat(controller: controller)
    }
    
    lazy var keyboardInterceptor: KeyboardInterceptor = {
        let interceptor = KeyboardInterceptor(
            targetCamera: controller.sceneCamera,
            targetCameraNode: controller.sceneCameraNode
        )
        interceptor.onNewFileOperation = onFileOperation(_:)
        interceptor.onNewFocusChange = onNewFocusChange(_:)
        return interceptor
    }()
    
    func attachMouseSink() {
        SceneLibrary.global.sharedMouse
            .receive(on: DispatchQueue.global(qos: .userInteractive))
            .sink { [inputCompat] mousePosition in
                inputCompat.newMousePosition(mousePosition)
            }
            .store(in: &controller.cancellables)
        
        SceneLibrary.global.sharedScroll
            .receive(on: DispatchQueue.global(qos: .userInteractive))
            .sink { [inputCompat] scrollEvent in
                inputCompat.newScrollEvent(scrollEvent)
            }
            .store(in: &controller.cancellables)
        
        SceneLibrary.global.sharedMouseDown
            .receive(on: DispatchQueue.global(qos: .userInteractive))
            .sink { [inputCompat] downEvent in
                inputCompat.newMouseDown(downEvent)
            }
            .store(in: &controller.cancellables)
    }
    
    func attachKeyInputSink() {
        SceneLibrary.global.sharedKeyEvent
            .receive(on: DispatchQueue.global(qos: .userInteractive))
            .sink { [inputCompat] event in
                inputCompat.newKeyEvent(event)
            }
            .store(in: &controller.cancellables)
    }
    
    func attachEventSink() {
        SceneLibrary.global.codePagesController.fileEventStream
            .receive(on: DispatchQueue.global(qos: .userInteractive))
            .sink { [inputCompat] event in
                inputCompat.controller.onNewFileStreamEvent(event)
            }
            .store(in: &controller.cancellables)
    }
    
    func attachSearchInputSink() {
        SceneLibrary.global.codePagesController.codeGridParser.query.searchStream
            .receive(on: DispatchQueue.global(qos: .userInteractive))
            .sink { [inputCompat] searchEvent in
                inputCompat.doNewSearch(searchEvent, SceneLibrary.global.codePagesController.sceneState)
            }
            .store(in: &controller.cancellables)
    }
    
    private func onFileOperation(_ op: FileOperation) {
        switch op {
        case .openDirectory:
            controller.requestSetRootDirectory()
        }
    }
    
    private func onNewFocusChange(_ focus: SelfRelativeDirection) {
        sceneTransaction {
            controller.codeGridParser.editorWrapper.changeFocus(focus)
        }
    }
}

class CodePagesControllerMacOSInputCompat {
    let controller: CodePagesController
    
    init(controller: CodePagesController) {
        self.controller = controller
    }
    
    var touchState: TouchState { controller.touchState }
    var sceneCameraNode: SCNNode { controller.sceneCameraNode }
    var sceneView: SCNView { controller.sceneView }
    var codeGridParser: CodeGridParser { controller.codeGridParser }
    var keyboardInterceptor: KeyboardInterceptor { controller.macosCompat.keyboardInterceptor }
    
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
        let translation: SCNMatrix4
        let targetNode: SCNNode
        if let hoveredSheet = touchState.mouse.currentHoveredSheet,
           event?.modifierFlags.contains(.control) == true {
            translation = SCNMatrix4MakeTranslation(scaledX, 0, scaledY)
            targetNode = hoveredSheet
        }
        //        else if event?.modifierFlags.contains(.command) == true {
        else if event?.modifierFlags.contains(.shift) == true {
            translation = SCNMatrix4MakeTranslation(scaledX, 0, scaledY)
            targetNode = sceneCameraNode
        } else {
            translation = SCNMatrix4MakeTranslation(scaledX, scaledY, 0)
            targetNode = sceneCameraNode
        }
        
        sceneTransaction(0) {
            let translate4x4 = simd_float4x4(translation)
            let target4x4 = simd_float4x4(targetNode.transform)
            let multiplied = simd_mul(translate4x4, target4x4)
            targetNode.simdTransform = multiplied
            //            targetNode.transform = SCNMatrix4Mult(translation, targetNode.transform)
        }
    }
    
    func newMouseDown(_ event: NSEvent) {
        var safePoint: CGPoint?
        DispatchQueue.main.sync {
            safePoint = sceneView.convert(event.locationInWindow, to: nil)
        }
        guard let point = safePoint else { return }
        
        guard let _ = sceneView.hitTestCodeSheet(
            with: point, .all, .rootCodeSheet
        ).first?.node.parent else { return }
    }
    
    func newKeyEvent(_ event: NSEvent) {
        keyboardInterceptor.onNewKeyEvent(event)
    }
    
    func newMousePosition(_ point: CGPoint) {
        // this should be a single walk with a switch that handles the node each time. this is slow otherwise, lots of
        // O(M * N) operations on each position update which is Woof.
        doCodeGridHover(point)
    }
    
    
    class SearchContainer {
        var codeGridFocus: CodeGridFocus
        var codeGridParser: CodeGridParser
        
        init(codeGridParser: CodeGridParser,
             codeGridFocus: CodeGridFocus) {
            self.codeGridParser = codeGridParser
            self.codeGridFocus = codeGridFocus
        }
        
        func search(_ newInput: String, _ state: SceneState) {
            print("new search ---------------------- [\(newInput)]")
            var toAdd: [CodeGrid] = []
            var toRemove: [CodeGrid] = []
            codeGridParser.query.walkGridsForSearch(
                newInput,
                onPositive: { foundInGrid, leafInfo in
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

            }
            print("----------------------")
        }
    }
    lazy var searchController = {
        SearchContainer(codeGridParser: codeGridParser,
                        codeGridFocus: focus)
    }()
    lazy var focus: CodeGridFocus = {
        let rootGrid = codeGridParser.createNewGrid()
            .backgroundColor(NSUIColor(displayP3Red: 0.3, green: 0.3, blue: 0.4, alpha: 0.2))
        let focus = CodeGridFocus(
            rootGrid: rootGrid
        )
        controller.sceneState.rootGeometryNode.addChildNode(focus.rootGrid.rootNode)
        return focus
    }()
    
    func doNewSearch(_ newInput: String, _ state: SceneState) {
        searchController.search(newInput, state)
    }
    
    private func doCodeGridHover(_ point: CGPoint) {
        
        let gridsAndTokens = sceneView.hitTest(location: point, .gridsAndTokens)
        var iterator = gridsAndTokens.makeIterator()
        var (hoveredId, tokenSet, grid): (String?, CodeGridNodes?, CodeGrid?)
        
        while tokenSet == nil && grid == nil, let next = iterator.next() {
            guard let codeGridIdFromNode = next.node.name else {
                print("No name for node: \(next.node)")
                continue
            }
            
            if tokenSet == nil {
                let hovered = codeGridParser.tokenCache[codeGridIdFromNode]
                hoveredId = codeGridIdFromNode
                tokenSet = hovered
            }
            
            if grid == nil,
               let letMaybeParentNameId = next.node.parent?.name,
               let maybeGrid = codeGridParser.concurrency[letMaybeParentNameId] {
                grid = maybeGrid
            }
        }
    
        if let hoveredInfo = grid?.codeGridSemanticInfo {
            self.hoveredInfo = hoveredInfo
        }
        
        if let hoveredToken = hoveredId {
            if let set = tokenSet, !set.isEmpty {
                touchState.mouse.hoverTracker.newSetHovered(set)
                self.hoveredToken = hoveredToken
            }
            
        }
    }
}
