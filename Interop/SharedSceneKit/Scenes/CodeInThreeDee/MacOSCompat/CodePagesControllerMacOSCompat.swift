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
import SwiftUI

class CodePagesControllerMacOSCompat {
    let controller: CodePagesController
    let inputCompat: CodePagesControllerMacOSInputCompat
    let engine: FocusBoxLayoutEngine
    
    lazy var resizeCommand = inputCompat.focus.resize
    lazy var layoutCommand = inputCompat.focus.layout
    lazy var insertControl = parser.gridCache.insertControl
    
    init(controller: CodePagesController) {
        self.controller = controller
        self.inputCompat = CodePagesControllerMacOSInputCompat(controller: controller)
        self.engine = FocusBoxEngineMacOS()
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
}

extension CodePagesControllerMacOSCompat: CommandHandler {
    func handleSingleCommand(_ path: FileKitPath, _ style: FileBrowser.Event.SelectType) {
        switch style {
        case .addToFocus:
            guard let newGrid = renderAndCache(path) else { return }
            doAddToFocus(newGrid)
        case .addToWorld:
            guard let newGrid = renderAndCache(path) else { return }
            doAddToRoot(rootGrid: newGrid)
        case .focusOnExistingGrid:
            guard let cachedGrid = parser.gridCache.get(path)?.source else { return }
            focusOnGrid(target: cachedGrid)
        }
    }
}

private extension CodePagesControllerMacOSCompat {
    func focusOnGrid(target: CodeGrid) {
        controller.zoom(to: target)
    }
}


private extension CodePagesControllerMacOSCompat {
    func doAddToRoot(rootGrid: CodeGrid) {
        controller.sceneState.rootGeometryNode.addChildNode(rootGrid.rootNode)
    }
}

private extension CodePagesControllerMacOSCompat {
    func doAddToFocus(_ newGrid: CodeGrid) {
        resizeCommand { _, box in
            sceneTransaction(0) { layoutCommand { focus, box in
                focus.addGridToFocus(newGrid, box.deepestDepth + 1)
            }}
            
            if box.deepestDepth != 0 {
                sceneTransaction {
                    switch box.layoutMode {
                    case .horizontal:
                        box.rootNode.simdTranslate(dX: -newGrid.measures.lengthX)
                    case .stacked:
                        box.rootNode.simdTranslate(dZ: VectorVal(-150.0).vector)
                    case .userStack:
                        print("Seriously userStack isn't supported on mac yet")
                    }
                }
            }
            
            //TODO: The control is off by a few points.. WHY!?
            let swapControl = GridControlSwapModes(newGrid, inputCompat.focus).applying {
                insertControl($0)
                newGrid.addingChild($0)
                
                $0.setPositionConstraint(
                    target: newGrid.rootContainerNode,
                    positionOffset: SCNVector3(
                        0, $0.displayGrid.measures.lengthY + 2.0, 0
                    )
                )
            }
            
            GridControlAddToFocus(newGrid, inputCompat.focus).applying {
                insertControl($0)
                newGrid.addingChild($0)
                
                $0.setPositionConstraint(
                    target: swapControl.displayGrid.rootNode,
                    positionOffset: SCNVector3(
                        swapControl.displayGrid.measures.lengthX + 4.0, 0, 0
                    )
                )
            }
        }
        
    }
}

extension CodePagesControllerMacOSCompat {
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
}

private extension CodePagesControllerMacOSCompat {
    func onFileOperation(_ op: FileOperation) {
        switch op {
        case .openDirectory:
            controller.requestSetRootDirectory()
        }
    }
    
    func onNewFocusChange(_ focus: SelfRelativeDirection) {
        sceneTransaction {
            guard let nextGrid = inputCompat.focus.updateBoxFocusedGrid(inDirection: focus) else {
                print("No grid in direction: \(focus)")
                return
            }
            
            guard let parent = nextGrid.rootNode.parent else {
                print("For \(focus), missing parent on grid: \(nextGrid)")
                return
            }
            
            var startPosition: SCNVector3 = parent
                .convertPosition(nextGrid.rootNode.position, to: nil)
                .translated(
                    dX: nextGrid.measures.lengthX / 2.0,
                    dY: -min(32, nextGrid.measures.lengthY / 4.0)
                )
            
            
            if inputCompat.searchController.hasActiveSearch,
               let clone = findClone(of: nextGrid) {
//                let clonePosition = parent.convertPosition(clone.rootNode.position, to: nil)
                startPosition = startPosition.translated(dX: clone.measures.lengthX / 2.0)
                
//                let centerX = (clone.measures.centerX + nextGrid.measures.centerX) / 2.0
//                let centerY = (clone.measures.centerY + nextGrid.measures.centerY) / 2.0
//                let centerZ = startPosition.z + (clone.measures.centerZ + nextGrid.measures.centerZ) / 2.0
//                let center = SCNVector3(centerX, centerY, centerZ)
//                controller.sceneCameraNode.look(at: center)
            }
            
            controller.sceneCameraNode.position = startPosition.translated(
                dZ: default__CameraSpacingFromPlaneOnShift
            )
        }
    }
    
    func findClone(of grid: CodeGrid) -> CodeGrid? {
        return controller.codeGridParser.gridCache.cachedGrids[grid.id]?.clone
    }
}
