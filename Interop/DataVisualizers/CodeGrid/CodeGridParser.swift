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
    
    lazy var editorWrapper: CodeGridWorld = {
        let world = CodeGridWorld(cameraProvider: {
            self.cameraNode
        })
        return world
    }()
    
    var cameraNode: SCNNode?
    
    func withNewGrid(_ url: URL, _ operation: (CodeGridWorld, CodeGrid) -> Void) {
        if let grid = renderGrid(url) {
            operation(editorWrapper, grid)
        }
    }
    
    func withNewGrid(_ source: String, _ operation: (CodeGridWorld, CodeGrid) -> Void) {
        if let grid = renderGrid(source) {
            operation(editorWrapper, grid)
        }
    }
    
    func renderGrid(_ url: URL) -> CodeGrid? {
        guard let sourceFile = loadSourceUrl(url) else { return nil }
		let newGrid = createGrid(sourceFile)
        return newGrid
    }
    
    func renderGrid(_ source: String) -> CodeGrid? {
        guard let sourceFile = parse(source) else { return nil }
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
    
//    let rootGridColor = NSUIColor(calibratedRed: 0.0, green: 0.4, blue: 0.6, alpha: 0.2)
    let rootGridColor = NSUIColor(displayP3Red: 0.0, green: 0.4, blue: 0.6, alpha: 0.2)
    
    private let renderQueue = DispatchQueue(label: "RenderClock", qos: .userInitiated)
    
    func __versionTwo__RenderPathAsRoot(
        _ rootPath: FileKitPath,
        _ immediateReceiver: ((CodeGrid) -> Void)? = nil
    ) {
        let snapping = WorldGridSnapping()
        
        func makeFileNameGrid(_ name: String) -> CodeGrid {
            let newGrid = newGrid().backgroundColor(.black)
                .consume(text: name)
                .sizeGridToContainerNode()
            newGrid.rootNode.categoryBitMask = HitTestType.semanticTab.rawValue
            newGrid.backgroundGeometryNode.categoryBitMask = HitTestType.semanticTab.rawValue
            return newGrid
        }
        
        func makeGridForDirectory2(_ rootDirectory: FileKitPath, _ depth: Int) -> CodeGrid {
            let rootDirectoryGrid = newGrid().backgroundColor(
                rootGridColor.withAlphaComponent(rootGridColor.alphaComponent * VectorFloat(depth))
            )
            
            var fileStack: [FileKitPath] = []
            var directoryStack: [FileKitPath] = []
            
            // Add each child to stack for processing
            forEachChildOf(rootDirectory) { index, childPath in
                if childPath.isDirectory {
                    directoryStack.insert(childPath, at: 0)
                } else {
                    fileStack.insert(childPath, at: 0)
                }
            }
            
            // Pop all files and render them vertically
            var lastDirectChildGrid: CodeGrid?
            while let last = fileStack.popLast() {
                print("File *** \(last.url.lastPathComponent)")
                guard let newGrid = renderGrid(last.url) else {
                    print("No grid rendered for \(last)")
                    continue
                }
                
                newGrid.rootNode.position.z = 4.0
                if let lastGrid = lastDirectChildGrid {
                    snapping.connectWithInverses(sourceGrid: lastGrid, to: [.right(newGrid)])
                    newGrid.rootNode.position = lastGrid.rootNode.position.translated(
                        dX: lastGrid.rootNode.lengthX + 8.0,
                        dY: 0,
                        dZ: 0
                    )
                }
                lastDirectChildGrid = newGrid
                rootDirectoryGrid.rootNode.addChildNode(newGrid.rootNode)
                
                let fileName = makeFileNameGrid(last.url.lastPathComponent)
                fileName.rootNode.position = SCNVector3Zero.translated(
                    dY: fileName.rootNode.lengthY + 2.0,
                    dZ: 4.0
                )
                newGrid.rootNode.addChildNode(fileName.rootNode)
            }
            
            // all files haves been rendered for this directory; move focus back to the left-most
            var firstGridInLastRow: CodeGrid?
            var maxHeight = lastDirectChildGrid?.rootNode.lengthY ?? VectorFloat(0.0)
            var nexRowStartPosition = SCNVector3Zero
            if let start = lastDirectChildGrid {
                snapping.iterateOver(start, direction: .left) { grid in
                    maxHeight = max(maxHeight, grid.rootNode.lengthY)
                    firstGridInLastRow = grid
                }
                nexRowStartPosition = nexRowStartPosition.translated(dY: -maxHeight - 8.0)
            }
            
            nexRowStartPosition = nexRowStartPosition.translated(dZ: 32.0 * VectorFloat(depth))
            while let last = directoryStack.popLast() {
                print("Dir <--> \(last.url.lastPathComponent)")
                let childDirectory = makeGridForDirectory2(last, depth + 1)
                
                rootDirectoryGrid.rootNode.addChildNode(childDirectory.rootNode)
                childDirectory.rootNode.position = nexRowStartPosition
                
                let fileName = makeFileNameGrid(last.url.lastPathComponent).backgroundColor(.blue)
                fileName.rootNode.position = SCNVector3Zero.translated(
                    dY: fileName.rootNode.lengthY * 6 + 2.0,
                    dZ: 8.0
                )
                fileName.rootNode.scale = SCNVector3(x: 3.0, y: 3.0, z: 1.0)
                childDirectory.rootNode.addChildNode(fileName.rootNode)
                
                nexRowStartPosition = nexRowStartPosition.translated(
                    dX: childDirectory.rootNode.lengthX + 8
                )
            }
            
            return rootDirectoryGrid.sizeGridToContainerNode()
        }
        
        // Kickoff
        renderQueue.async {
            let newRootGrid = makeGridForDirectory2(rootPath, 1)
            immediateReceiver?(newRootGrid)
        }
    }
    
    func makeGridsForRootDirectory(_ rootPath: FileKitPath) -> CodeGrid {
        let rootGrid = newGrid().backgroundColor(rootGridColor)
        
        func stackVertical(_ index: Int, _ newGrid: CodeGrid) {
            editorWrapper.addGrid(style: .inNextRow(newGrid))
        }
        
        func stackHorizontal(_ index: Int, _ newGrid: CodeGrid) {
            editorWrapper.addGrid(style: .trailingFromLastGrid(newGrid))
        }
        
        func stackOrthogonal(_ index: Int, _ newGrid: CodeGrid) {
            editorWrapper.addGrid(style: .inNextPlane(newGrid))
        }
        
        func doMainLoop(_ index: Int, _ pathChild: FileKitPath) {
            if pathChild.isDirectory {
                let newGrid = renderDirectoryInLine(pathChild).translated(dY: 4.0)
                stackOrthogonal(index, newGrid)
            } else if let childGrid = renderGrid(pathChild.url) {
                let newGrid = childGrid.translated(dZ: 4.0)
                stackVertical(index, newGrid)
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
    
//    private let directoryColor: NSUIColor = NSUIColor(calibratedRed: 0.2, green: 0.6, blue: 0.8, alpha: 0.2)
    private let directoryColor: NSUIColor = NSUIColor(displayP3Red: 0.2, green: 0.6, blue: 0.8, alpha: 0.2)
    
    private func renderDirectoryInLine(_ path: FileKitPath) -> CodeGrid {
        let newParentGrid = newGrid().backgroundColor(directoryColor)
        var lastChild: CodeGrid?
        
        forEachChildOf(path) { _, pathChild in
            guard let childGrid = makeGridFromPathType(pathChild) else { return }
            
            let lastLengthX = lastChild?.rootNode.lengthY ?? 0
            let lastPosition = lastChild?.rootNode.position ?? SCNVector3Zero
            let translatedPosition = lastPosition.translated(dY: lastLengthX + 8, dZ: 1.0)
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
    var worldGridEditor = WorldGridEditor()
    var cameraProvider: (() -> SCNNode?)?
    
    init(cameraProvider: (() -> SCNNode?)?) {
        self.cameraProvider = cameraProvider
    }
    
    func addInFrontOfCamera(style: WorldGridEditor.AddStyle) {
        #if os(iOS)
        guard let cam = cameraProvider?() else { return }
        
        let gridNode = style.grid.rootNode
        
        gridNode.simdPosition = cam.simdPosition
        gridNode.simdPosition += cam.simdWorldFront * 0.5
        
        gridNode.simdEulerAngles.y = cam.simdEulerAngles.y
        gridNode.simdEulerAngles.x = cam.simdEulerAngles.x
//        gridNode.simdEulerAngles.z = cam.simdEulerAngles.z
        gridNode.scale = SCNVector3(x: 0.01, y: 0.01, z: 0.01)
        
        gridNode.simdPosition += -cam.simdWorldRight * (0.5 * gridNode.lengthX * 0.01)
        rootContainerNode.addChildNode(gridNode)
        #endif
    }
    
    func addGrid(style: WorldGridEditor.AddStyle) {
        worldGridEditor.transformedByAdding(style)
//        rootContainerNode.addChildNode(style.grid.rootNode)
    }
    
    func changeFocus(_ direction: SelfRelativeDirection) {
        worldGridEditor.shiftFocus(direction)
        moveCameraToFocus()
    }
    
    private func moveCameraToFocus() {
        guard let camera = cameraProvider?(),
              let grid = worldGridEditor.lastFocusedGrid
        else {
            print("updated focus to empty grid")
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
