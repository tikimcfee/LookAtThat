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

