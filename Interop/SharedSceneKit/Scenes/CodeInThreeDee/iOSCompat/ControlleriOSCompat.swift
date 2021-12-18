//
//  ControlleriOSCompat.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 12/17/21.
//

import Foundation
import SceneKit

class ControlleriOSCompat {
    let controller: CodePagesController
    let inputCompat: CodePagesInput
    let engine: FocusBoxLayoutEngine
    
    lazy var focus: CodeGridFocusController = {
        let focus = CodeGridFocusController(
            controller: controller
        )
        return focus
    }()
    
    init(controller: CodePagesController) {
        self.controller = controller
        self.inputCompat = CodePagesInput(controller: controller)
        self.engine = CompatiOSFocusBoxLayoutEngine()
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
//        SceneLibrary.global.codePagesController.codeGridParser.query.searchStream
//            .receive(on: DispatchQueue.global(qos: .userInteractive))
//            .sink { [inputCompat] searchEvent in
//                print("skip \(searchEvent)")
//            }
//            .store(in: &controller.cancellables)
    }
}

extension ControlleriOSCompat: CommandHandler {
    func handleSingleCommand(_ path: FileKitPath, _ style: FileBrowser.Event.SelectType) {
        guard let newGrid = renderAndCache(path) else { return }
        
        focus.addGridToFocus(newGrid, focus.mainFocus.deepestDepth + 1)
//        parser.editorWrapper.addInFrontOfCamera(grid: newGrid)
    }
}

struct CompatiOSFocusBoxLayoutEngine: FocusBoxLayoutEngine {
    func layout(_ container: FBLEContainer) {
        
    }
    
    func onSetBounds(_ container: FBLEContainer, _ newValue: Bounds) {
        // Set the size of the box to match
        let pad: VectorFloat = 32.0
        let halfPad: VectorFloat = pad / 2.0
        
        container.rootGeometry.width = (BoundsWidth(newValue) + pad).cg
        container.rootGeometry.height = (BoundsHeight(newValue) + pad).cg
        container.rootGeometry.length = (BoundsLength(newValue) + pad).cg
        
        let rootWidth = container.rootGeometry.width.vector
        let rootHeight = container.rootGeometry.height.vector
        
        /// translate geometry:
        /// 1. so it's top-left-front is at (0, 0, 1/2 length)
        /// 2. so it's aligned with the bounds of the grids themselves.
        /// Note: this math assumes nothing has been moved from the origin
        
        let translateX = -1.0 * rootWidth / 2.0 - newValue.min.x + halfPad
        let translateY = rootHeight / 2.0 - newValue.max.y - halfPad
        let translateZ = -newValue.min.z / 2.0
        
        container.geometryNode.pivot = SCNMatrix4MakeTranslation(
            translateX, translateY, translateZ
        )
    }
}
