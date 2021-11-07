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
    
    let world = CodeGridWorld()
    
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

class CodeGridWorld {
    var rootContainerNode: SCNNode = SCNNode()
    var worldGrid = WorldGridEditor()
    var focusPosition: (Int, Int, Int) = (0, 0, 0)
    
    private let default_gridWidth = 3
    private var columnIndex = 0
    private var rowIndex = 0
    
    var gridCache: [CodeGrid] = []
    var lastGrid: CodeGrid?
    
    init() {
        
    }
    
    func addGrid(style: WorldGridEditor.AddStyle) {
        worldGrid.transformedByAdding(style)
        rootContainerNode.addChildNode(style.grid.rootNode)
    }
    
    func updateFocus(_ direction: SelfRelativeDirection, _ cameraNode: SCNNode) {
        let lastFocusPosition = focusPosition
        switch direction {
        case .left:
            focusPosition = (
                max(0, focusPosition.0 - 1),
                focusPosition.1,
                focusPosition.2
            )
        case .down:
            focusPosition = (
                focusPosition.0,
                max(0, focusPosition.1 - 1),
                focusPosition.2
            )
        case .backward:
            focusPosition = (
                focusPosition.0,
                focusPosition.1,
                max(0, focusPosition.2 - 1)
            )
        case .right:
            focusPosition = (
//                min(focusPosition.0 + 1, worldGrid.lastRowGridIndex),
                focusPosition.0 + 1,
                focusPosition.1,
                focusPosition.2
            )
        case .up:
            focusPosition = (
                focusPosition.0,
//                min(focusPosition.1 + 1, worldGrid.lastPlaneRowIndex),
                focusPosition.1 + 1,
                focusPosition.2
            )
        case .forward:
            focusPosition = (
                focusPosition.0,
                focusPosition.1,
//                min(focusPosition.2 + 1, worldGrid.lastPlaneIndex)
                focusPosition.2 + 1
            )
        }
        
        worldGrid.gridAt(
            z: focusPosition.2,
            y: focusPosition.1,
            x: focusPosition.0
        ) { grid in
            sceneTransaction {
                let gridX = grid.rootNode.lengthX
                let gridY = grid.rootNode.lengthY
                grid.rootNode.position = grid.rootNode.position.translated(
                    dX: 0.0,
                    dY: gridY / 2.0,
                    dZ: 0.0
                )
                cameraNode.position = grid.rootNode.position.translated(
                    dX: gridX / 2.0,
                    dY: -gridY / 4.0,
                    dZ: 128.0
                )
            }
        }
        worldGrid.gridAt(
            z: lastFocusPosition.2,
            y: lastFocusPosition.1,
            x: lastFocusPosition.0
        ) { grid in
            sceneTransaction {
                let gridX = grid.rootNode.lengthX
                let gridY = grid.rootNode.lengthY
                grid.rootNode.position = grid.rootNode.position.translated(
                    dX: 0.0,
                    dY: -gridY / 2.0,
                    dZ: 0.0
                )
            }
        }
    }
}
