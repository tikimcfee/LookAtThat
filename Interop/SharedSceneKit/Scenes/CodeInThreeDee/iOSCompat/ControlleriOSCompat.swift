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
        
        let resizeCommand = inputCompat.focus.resize
        let layoutCommand = inputCompat.focus.layout
        let insertControl = parser.gridCache.insertControl
        
        switch style {
        case .addToFocus:
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
                        }
                    }
                }
                
                //TODO: The control is off by a few points.. WHY!?
                let swapControl = CGCSwapModes(newGrid).applying {
                    insertControl($0)
                    newGrid.addingChild($0.displayGrid)
                    
                    $0.displayGrid.measures
                        .setBottom(newGrid.measures.topOffset + 2)
                        .setLeading(newGrid.measures.leadingOffset)
                        .setFront(newGrid.measures.frontOffset)
                }
                
                CGCAddToFocus(newGrid, inputCompat.focus).applying {
                    insertControl($0)
                    newGrid.addingChild($0.displayGrid)
                    
                    $0.displayGrid.measures
                        .setBottom(newGrid.measures.topOffset + 2)
                        .setLeading(swapControl.displayGrid.measures.trailingOffset + 4.0)
                        .setFront(swapControl.displayGrid.measures.backOffset)
                }
            }
            
        case .addToWorld:
            break
        }
    }
}

struct CompatiOSFocusBoxLayoutEngine: FocusBoxLayoutEngine {
    func onSetBounds(_ container: FBLEContainer, _ newValue: Bounds) {
        // Set the size of the box to match
        let pad: VectorFloat = 32.0 * DeviceScale
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
        /// Note: -1.0 as multiple is explicit to remain compatiable between iOS macOS; '-' operand isn't universal
        let translateX = -1.0 * rootWidth / 2.0 - newValue.min.x + halfPad
        let translateY = rootHeight / 2.0 - newValue.max.y - halfPad
        let translateZ = -newValue.min.z / 2.0
        
        container.geometryNode.pivot = SCNMatrix4MakeTranslation(
            translateX, translateY, translateZ
        )
    }
    
    func layout(_ container: FBLEContainer) {
        guard let first = container.box.bimap[0] else {
            print("No depth-0 grid to start layout")
            return
        }
        
        let xLengthPadding: VectorFloat = 8.0 * DeviceScale
        let zLengthPadding: VectorFloat = 150.0 * DeviceScale
        
        sceneTransaction {
            switch container.box.layoutMode {
            case .horizontal:
                horizontalLayout()
            case .stacked:
                stackLayout()
            }
        }
        
        func horizontalLayout() {
            container.box.snapping.iterateOver(first, direction: .right) { previous, current, _ in
                if let previous = previous {
                    current.measures
                        .setTop(previous.measures.top)
                        .setLeading(previous.measures.trailing + xLengthPadding)
                        .setBack(previous.measures.back)
                } else {
                    current.zeroedPosition()
                }
            }
        }
        
        func stackLayout() {
            container.box.snapping.iterateOver(first, direction: .forward) { previous, current, _ in
                if let previous = previous {
                    current.measures
                        .setTop(previous.measures.top)
                        .alignedCenterX(previous)
                        .setBack(previous.measures.back - zLengthPadding)
                } else {
                    current.zeroedPosition()
                }
            }
        }
    }
}
