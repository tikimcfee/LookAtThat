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
    
    func renderDirectory(_ path: FileKitPath) -> CodeGrid? {
        guard path.isDirectory else { return nil }
        let newDirectoryRoot = makeGridsForRootDirectory(path)
        return newDirectoryRoot
    }
    
    private func createGrid(_ syntax: SourceFileSyntax) -> CodeGrid {
        let grid = newGrid()
            .consume(syntax: Syntax(syntax))
            .sizeGridToContainerNode()
        return grid
    }
    
    private func newGrid() -> CodeGrid {
        CodeGrid(
            glyphCache: glyphCache,
            tokenCache: tokenCache
        )
    }
    
    private func forEachChildOf(_ path: FileKitPath, _ receiver: (Int, FileKitPath) -> Void) {
        path.children()
            .filter(FileBrowser.isFileObserved)
            .sorted(by: FileBrowser.sortedFilesFirst)
            .enumerated()
            .forEach(receiver)
    }
    
    let rootGridColor = NSUIColor(calibratedRed: 0.0, green: 0.4, blue: 0.6, alpha: 0.2)
    func makeGridsForRootDirectory(_ rootPath: FileKitPath) -> CodeGrid {
        let rootGrid = newGrid().backgroundColor(rootGridColor)
        
        var lastRenderedGrid: CodeGrid?
        
        func stackVertical(_ index: Int, _ newGrid: CodeGrid) {
            let lastStart = lastRenderedGrid?.rootNode.position.y ?? 0
            let lastLength = lastRenderedGrid?.rootNode.lengthY ?? 0
            let space = index == 0 ? 0.0 : 2.0
            
            rootGrid.rootNode.addChildNode(newGrid.rootNode)
            newGrid.translated(dY: lastStart - lastLength - space)
        }
        
        func stackHorizontal(_ index: Int, _ newGrid: CodeGrid) {
            let lastStart = lastRenderedGrid?.rootNode.position.x ?? 0
            let lastLength = lastRenderedGrid?.rootNode.lengthX ?? 0
            let space = index == 0 ? 0.0 : 4.0
            
            rootGrid.rootNode.addChildNode(newGrid.rootNode)
            newGrid.translated(dX: lastStart + lastLength + space)
        }
        
        func stackOrthogonal(_ index: Int, _ newGrid: CodeGrid) {
            let lastStart = lastRenderedGrid?.rootNode.position.z ?? 0
            let lsatLength = lastRenderedGrid?.rootNode.lengthZ ?? 0
            let space = index == 0 ? 0.0 : 16.0
            
            rootGrid.rootNode.addChildNode(newGrid.rootNode)
            newGrid.translated(dX: 8.0, dZ: lastStart + lsatLength + space)
        }
        
        func doMainLoop(_ index: Int, _ pathChild: FileKitPath) {
            if pathChild.isDirectory {
                let newGrid = renderDirectoryInLine(pathChild).translated(dX: 4.0)
                stackOrthogonal(index, newGrid)
                lastRenderedGrid = newGrid
                
            } else if let childGrid = renderGrid(pathChild.url) {
                let newGrid = childGrid.translated(dZ: 4.0)
                stackVertical(index, newGrid)
                lastRenderedGrid = newGrid
                
            } else {
                print("No grid for \(pathChild)")
                return
            }
        }
        
        forEachChildOf(rootPath) { index, pathChild in
            doMainLoop(index, pathChild)
        }
        return rootGrid.sizeGridToContainerNode(pad: 2)
    }
    
    private let directoryColor: NSUIColor = NSUIColor(calibratedRed: 0.2, green: 0.6, blue: 0.8, alpha: 0.2)
    private func renderDirectoryInLine(_ path: FileKitPath) -> CodeGrid {
        let newParentGrid = newGrid().backgroundColor(directoryColor)
        var lastChild: CodeGrid?
        
        forEachChildOf(path) { _, pathChild in
            guard let childGrid = makeGridFromPathType(pathChild) else { return }
            
            let lastLengthX = lastChild?.rootNode.lengthX ?? 0
            let lastPosition = lastChild?.rootNode.position ?? SCNVector3Zero
            let translatedPosition = lastPosition.translated(dX: lastLengthX + 8, dZ: 1.0)
            childGrid.rootNode.position = translatedPosition
                
            newParentGrid.rootNode.addChildNode(childGrid.rootNode)
            lastChild = childGrid
        }
        
        return newParentGrid.sizeGridToContainerNode(pad: 2.0)
    }
    
    private func makeGridFromPathType(_ path: FileKitPath) -> CodeGrid? {
        if path.isDirectory {
            return makeGridsForRootDirectory(path)
        } else {
            return renderGrid(path.url)
        }
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
    }
    
    func changeFocus(_ direction: SelfRelativeDirection) {
        worldGrid.shiftFocus(direction)
        moveCameraToFocus()
    }
    
    private func moveCameraToFocus() {
        guard let camera = cameraProvider?(),
              let grid = worldGrid.gridAtFocusPosition
        else {
            print("updated focus to empty grid: \(worldGrid.focusPosition)")
            return
        }
        camera.position = grid.rootNode.position.translated(
            dX: grid.rootNode.lengthX / 2.0,
            dY: -min(32, grid.rootNode.lengthY / 4.0),
            dZ: default__CameraSpacingFromPlaneOnShift
        )
    }
}

class WorldGridNavigator {
    var directions: [String: Set<SelfRelativeDirection>] = [:]
    
    func isMovementAllowed(_ grid: CodeGrid, _ direction: SelfRelativeDirection) -> Bool {
        directionsForGrid(grid).contains(direction)
    }
    
    func directionsForGrid(_ grid: CodeGrid) -> Set<SelfRelativeDirection> {
        directions[grid.id] ?? []
    }
    
    func allowMovement(from grid: CodeGrid, to direction: SelfRelativeDirection) {
        var toAllow = directions[grid.id] ?? []
        toAllow.insert(direction)
        directions[grid.id] = toAllow
    }
}
