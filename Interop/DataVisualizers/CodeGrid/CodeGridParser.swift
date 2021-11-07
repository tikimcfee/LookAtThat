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

class CodeGridWorld {
    var rootContainerNode: SCNNode = SCNNode()
    var worldGrid = WorldGridEditor()
    var cameraProvider: (() -> SCNNode?)?
    
    init(cameraProvider: (() -> SCNNode?)?) {
        self.cameraProvider = cameraProvider
    }
    
    func addGrid(style: WorldGridEditor.AddStyle) {
        worldGrid.transformedByAdding(style)
        rootContainerNode.addChildNode(style.grid.rootNode)
        
        guard let camera = cameraProvider?() else { return }
        camera.position = style.grid.rootNode.position.translated(
            dX: style.grid.rootNode.lengthX / 2.0,
            dY: -style.grid.rootNode.lengthY / 4.0,
            dZ: default__CameraSpacingFromPlaneOnShift
        )
    }
    
    func changeFocus(_ direction: SelfRelativeDirection) {
        worldGrid.shiftFocus(direction)
        
        guard let camera = cameraProvider?(),
              let grid = worldGrid.gridAtFocusPosition
        else {
            print("updated focus to empty grid: \(worldGrid.focusPosition)")
            return
        }
        camera.position = grid.rootNode.position.translated(
            dX: grid.rootNode.lengthX / 2.0,
            dY: -grid.rootNode.lengthY / 4.0,
            dZ: default__CameraSpacingFromPlaneOnShift
        )
    }
}
