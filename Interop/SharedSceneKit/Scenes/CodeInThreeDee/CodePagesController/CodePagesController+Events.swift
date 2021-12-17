//
//  CodePagesController+Events.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 12/16/21.
//

import Foundation
import SceneKit
import SwiftSyntax
import Combine
import FileKit

extension CodePagesController {

#if os(macOS)
    
    func handleSingleCommand(_ path: FileKitPath, _ style: FileBrowser.Event.SelectType) {
        guard let newGrid = codeGridParser.renderGrid(path.url) else {
            print("No code grid we cry")
            return
        }
        
        let resizeCommand = macosCompat.inputCompat.focus.resize
        let layoutCommand = macosCompat.inputCompat.focus.layout
        let insertControl = codeGridParser.gridCache.insertControl
        
        switch style {
        case .addToFocus:
            resizeCommand { _, box in
                sceneTransaction(0) { layoutCommand { focus, box in
                    focus.addGridToFocus(newGrid, box.deepestDepth + 1)
                }}
                
                sceneTransaction {
                    box.rootNode.simdTranslate(dX: -newGrid.measures.lengthX)
                }
                
                //TODO: The control is off by a few points.. WHY!?
                let swapControl = CGCSwapModes(newGrid).applying {
                    insertControl($0)
                    newGrid.addingChild($0.displayGrid)
//                    box.gridNode.addingChild($0.displayGrid)
                    
                    $0.onAlign = {
                        $0.displayGrid.measures
                            .setBottom(newGrid.measures.topOffset + 2)
                            .setLeading(newGrid.measures.leadingOffset)
                            .setFront(newGrid.measures.frontOffset)
                        
                        return $0.displayGrid.rootNode.transform
                    }
                }
                
                CGCAddToFocus(newGrid, macosCompat.inputCompat.focus).applying {
                    insertControl($0)
                    newGrid.addingChild($0.displayGrid)
//                    box.gridNode.addingChild($0.displayGrid)
                    
                    $0.onAlign = {
                        $0.displayGrid.measures
                            .setBottom(newGrid.measures.topOffset + 2)
                            .setLeading(swapControl.displayGrid.measures.trailingOffset + 4.0)
                            .setFront(swapControl.displayGrid.measures.backOffset)
                        
                        return $0.displayGrid.rootNode.transform
                    }
                }
            }
            
        case .addToWorld:
            self.addToRoot(rootGrid: newGrid)
        }
        
        sceneTransaction {
            
        }
    }

#else
    
    func handleSingleCommand(_ path: FileKitPath, _ style: FileBrowser.Event.SelectType) {
        guard let newGrid = codeGridParser.renderGrid(path.url) else {
            print("No code grid we cry")
            return
        }
        
        let resizeCommand = macosCompat.inputCompat.focus.resize
        let layoutCommand = macosCompat.inputCompat.focus.layout
        let insertControl = codeGridParser.gridCache.insertControl
        
        switch style {
        case .addToFocus:
            resizeCommand { _, box in
                sceneTransaction(0) { layoutCommand { focus, box in
                    focus.addGridToFocus(newGrid, box.deepestDepth + 1)
                }}
                
                sceneTransaction {
                    box.rootNode.simdTranslate(dX: -newGrid.measures.lengthX)
                }
                
                //TODO: The control is off by a few points.. WHY!?
                CGCSwapModes(newGrid).applying {
                    insertControl($0)
                    box.gridNode.addingChild($0.displayGrid)
                }
            }
            
        case .addToWorld:
            self.addToRoot(rootGrid: newGrid)
        }
    }
    
#endif
    
}

