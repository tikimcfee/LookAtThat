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
    
    lazy var resizeCommand = inputCompat.focus.resize
    lazy var layoutCommand = inputCompat.focus.layout
    lazy var insertControl = parser.gridCache.insertControl
    
    init(controller: CodePagesController) {
        self.controller = controller
        self.inputCompat = CodePagesInput(controller: controller)
        self.engine = FocusBoxEngineiOS()
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

let Constants = (
    stackOffset: VectorFloat(-150 * DeviceScale),
    topOffsetPad: VectorFloat(2 * DeviceScale),
    trailingOffsetPad: VectorFloat(4 * DeviceScale)
)

extension ControlleriOSCompat: CommandHandler {
    func handleSingleCommand(_ path: FileKitPath, _ style: FileBrowser.Event.SelectType) {
        switch style {
        case .addToFocus:
            guard let newGrid = renderAndCache(path) else { return }
            doAddToFocus(newGrid)
        case .focusOnExistingGrid:
            guard let cachedGrid = parser.gridCache.get(path)?.source else { return }
            doHighlightFocus(cachedGrid)
        case .addToWorld:
            break
        }
    }
}

extension ControlleriOSCompat {
    func doHighlightFocus(_ codeGrid: CodeGrid) {
        guard let firstRootNode = codeGrid.consumedRootSyntaxNodes.first else { return }
        controller.setNewFocus(
            id: firstRootNode.id,
            in: codeGrid
        )
    }
}

extension ControlleriOSCompat {
    func doAddToFocus(_ newGrid: CodeGrid) {
        resizeCommand { _, box in
            sceneTransaction(0) { layoutCommand { focus, box in
                focus.addGridToFocus(newGrid, box.deepestDepth + 1)
            }}
            
            sceneTransaction {
                #if os(macOS)
                moveNewGrid(newGrid, box)
                #endif
                addControls(newGrid, box)
            }
        }
    }
    
    func moveNewGrid(_ newGrid: CodeGrid, _ box: FocusBox) {
        guard box.deepestDepth >= 0 else { return }
        
        sceneTransaction {
            switch box.layoutMode {
            case .horizontal:
                box.rootNode.simdTranslate(dX: -newGrid.measures.lengthX)
            case .stacked:
                box.rootNode.simdTranslate(dZ: Constants.stackOffset)
            case .userStack:
                print("iOS move new grid")
            }
        }
    }
    
    func addControls(_ newGrid: CodeGrid, _ box: FocusBox) {
        //TODO: The control is off by a few points.. WHY!?
        let swapControl = GridControlSwapModes(newGrid, inputCompat.focus).applying {
            insertControl($0)
            newGrid.addingChild($0)
        }
        
        swapControl.setPositionConstraint(
            target: newGrid.rootNode,
            positionOffset: SCNVector3(
                x: 0,
                y: swapControl.displayGrid.measures.lengthY + Constants.topOffsetPad,
                z: 0
            )
        )
        print("swap:----\n", swapControl.displayGrid.measures.dumpstats)
        
        let focusControl = GridControlAddToFocus(newGrid, inputCompat.focus).applying {
            insertControl($0)
            newGrid.addingChild($0)
        }
        focusControl.setPositionConstraint(
            target: swapControl.displayGrid.rootNode,
            positionOffset: SCNVector3(
                x: focusControl.displayGrid.measures.lengthX + Constants.trailingOffsetPad,
                y: 0,
                z: 0
            )
        )
        print("focusControl:----\n", focusControl.displayGrid.measures.dumpstats)
    }
}
