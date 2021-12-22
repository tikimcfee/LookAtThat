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
    private var defaultAttachUser: Bool { true }
    
    func handleSingleCommand(_ path: FileKitPath, _ style: FileBrowser.Event.SelectType) {
        guard let newGrid = renderAndCache(path) else { return }
        
        let resizeCommand = defaultAttachUser
            ? inputCompat.focus.userResize
            : inputCompat.focus.resize
        
        let layoutCommand = defaultAttachUser
            ? inputCompat.focus.userLayout
            : inputCompat.focus.layout
        
        let insertControl = parser.gridCache.insertControl
        
        switch style {
        case .addToFocus:
            resizeCommand { _, box in
                addToFocus()
                sceneTransaction {
                    #if os(macOS)
                    moveNewGrid(box)
                    #endif
                    addControls(box)
                }
            }
        case .addToWorld:
            break
        }
        
        func addToFocus() {
            sceneTransaction(0) { layoutCommand { focus, box in
                if defaultAttachUser {
                    focus.attachToUserFocus(newGrid, box.deepestDepth + 1)
                } else {
                    focus.addGridToFocus(newGrid, box.deepestDepth + 1)
                }
            }}
        }
        
        func moveNewGrid(_ box: FocusBox) {
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
        
        func addControls(_ box: FocusBox) {
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
}
