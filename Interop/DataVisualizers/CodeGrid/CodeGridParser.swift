//
//  CodeGridParser.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 10/22/21.
//

import Foundation
import SwiftSyntax
import SceneKit
import SwiftUI

class CodeGridParser: SwiftSyntaxFileLoadable {
    lazy var glyphCache: GlyphLayerCache = {
        GlyphLayerCache()
    }()
	
	lazy var tokenCache: CodeGridTokenCache = {
		CodeGridTokenCache()
	}()
    
    lazy var world: CodeGridWorld = {
        CodeGridWorld(cameraProvider: {
            self.cameraNode
        })
    }()
    
    var cameraNode: SCNNode?
    
    func withNewGrid(_ url: URL, _ operation: (CodeGridWorld, CodeGrid) -> Void) {
        if let grid = renderGrid(url) {
            operation(world, grid)
        }
    }
    
    func renderGrid(_ url: URL) -> CodeGrid? {
        guard let sourceFile = loadSourceUrl(url) else { return nil }
		let newGrid = createGrid(sourceFile)
        return newGrid
    }
    
    private func createGrid(_ syntax: SourceFileSyntax) -> CodeGrid {
        let grid = CodeGrid(glyphCache: glyphCache,
							tokenCache: tokenCache)
            .consume(syntax: Syntax(syntax))
            .sizeGridToContainerNode()
		
        return grid
    }
}

typealias FocusPosition = (Int, Int, Int)

private func left(_ focusPosition: FocusPosition) -> FocusPosition {
    (max(0, focusPosition.0 - 1), focusPosition.1, focusPosition.2)
}

private func down(_ focusPosition: FocusPosition) -> FocusPosition {
    (focusPosition.0, max(0, focusPosition.1 - 1), focusPosition.2)
}

private func backward(_ focusPosition: FocusPosition) -> FocusPosition {
    (focusPosition.0, focusPosition.1, max(0, focusPosition.2 - 1))
}

private func right(_ focusPosition: FocusPosition) -> FocusPosition {
    (max(0, focusPosition.0 + 1), focusPosition.1, focusPosition.2)
}

private func up(_ focusPosition: FocusPosition) -> FocusPosition {
    (focusPosition.0, max(0, focusPosition.1 + 1), focusPosition.2)
}

private func forward(_ focusPosition: FocusPosition) -> FocusPosition {
    (focusPosition.0, focusPosition.1, max(0, focusPosition.2 + 1))
}

class CodeGridWorld {
    var rootContainerNode: SCNNode = SCNNode()
    var worldGrid = WorldGridEditor()
    
    var focusPosition: FocusPosition = (-1, 0, 0)
    var lastFocusedGrid: CodeGrid?
    
    var cameraProvider: (() -> SCNNode?)?
    
    init(cameraProvider: (() -> SCNNode?)?) {
        self.cameraProvider = cameraProvider
    }
    
    func addGrid(style: WorldGridEditor.AddStyle) {
        worldGrid.transformedByAdding(style)
        rootContainerNode.addChildNode(style.grid.rootNode)
        
        guard let camera = cameraProvider?() else { return }
        
        switch style {
        case .trailingFromLastGrid:
            updateFocus(.right)
        case .inNextRow:
            focusPosition = (-1, focusPosition.1 + 1, focusPosition.2)
            updateFocus(.right)
        default:
            break
        }
    }
    
    func updateFocus(_ direction: SelfRelativeDirection) {
        switch direction {
        case .left:
            focusPosition = left(focusPosition)
        case .down:
            focusPosition = down(focusPosition)
        case .backward:
            focusPosition = backward(focusPosition)
        case .right:
            focusPosition = right(focusPosition)
        case .up:
            focusPosition = up(focusPosition)
        case .forward:
            focusPosition = forward(focusPosition)
        }
        doFocusRefresh()
    }
    
    func doFocusRefresh() {
//        if let lastFocusedGrid = lastFocusedGrid {
//            sceneTransaction {
//                let gridY = lastFocusedGrid.rootNode.lengthY
//                lastFocusedGrid.rootNode.position =
//                lastFocusedGrid.rootNode.position.translated(
//                    dX: 0.0,
//                    dY: -gridY / 4.0,
//                    dZ: 0.0
//                )
//            }
//        }
        
        worldGrid.gridAt(
            z: max(0, focusPosition.2),
            y: max(0, focusPosition.1),
            x: max(0, focusPosition.0)
        ) { grid in
            if grid == lastFocusedGrid { return }
            lastFocusedGrid = grid
            
            sceneTransaction {
                let gridX = grid.rootNode.lengthX
                let gridY = grid.rootNode.lengthY
                
//                grid.rootNode.position = grid.rootNode.position.translated(
//                    dX: 0.0,
//                    dY: gridY / 2.0,
//                    dZ: 0.0
//                )
                
                guard let camera = cameraProvider?() else { return }
                camera.position = grid.rootNode.position.translated(
                    dX: gridX / 2.0,
                    dY: -gridY / 4.0,
                    dZ: 128.0
                )
                
                //                cameraNode.look(at: grid.rootNode.position.translated(
                //                    dX: gridX / 2.0,
                //                    dY: -gridY / 4.0,
                //                    dZ: 0
                //                ))
                //                cameraNode.eulerAngles.z = 0
                
            }
        }
    }
    
    private func focusGrid(_ grid: CodeGrid) {
        if lastFocusedGrid == grid { return }
        
    }
}
