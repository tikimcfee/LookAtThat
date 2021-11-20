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
    ) -> CodeGrid {
        let newRootGrid = newGrid().backgroundColor(rootGridColor)
        editorWrapper.rootContainerNode = newRootGrid.rootNode
        immediateReceiver?(newRootGrid)
        
        func recurseIntoDirectory(_ directory: FileKitPath, root: CodeGrid) {
            // we're recursing but setting a side effect focus position.
            // retain the original position on entrance, and reset within the loop
            // to ensure the original containers are maintained for files.
            let originalContainerNode = editorWrapper.rootContainerNode
            forEachChildOf(directory) { index, childPath in
                if childPath.isDirectory {
                    maybeRenderClock?.wait()
                    print("Dir -> \(childPath.url.lastPathComponent)")
                    // start a new directory
                    let newDirectoryContainer = newGrid().backgroundColor(rootGridColor)
                    editorWrapper.rootContainerNode = newDirectoryContainer.rootNode
                    root.rootNode.addChildNode(newDirectoryContainer.rootNode)
                    
                    let lastGridRootNode = editorWrapper.worldGridEditor.lastFocusedGrid?.rootNode
                    let lastGridLengthX = lastGridRootNode?.lengthX ?? 0.0
                    let lastGridPosition = lastGridRootNode?.position ?? SCNVector3Zero
                    newDirectoryContainer.rootNode.position =
                        lastGridPosition.translated(dX: lastGridLengthX + 8.0, dY: 0, dZ: 128.0)
                    
                    recurseIntoDirectory(childPath, root: newDirectoryContainer)
                    newDirectoryContainer.sizeGridToContainerNode()
                } else {
                    maybeRenderClock?.wait()
                    print("File -> \(childPath.url.lastPathComponent)")
                    editorWrapper.rootContainerNode = originalContainerNode
                    guard let childGrid = renderGrid(childPath.url) else {
                        print("No grid rendered for \(childPath)")
                        return
                    }
                    // stack vertically or horizontally
                    self.editorWrapper.addGrid(style: .inNextRow(childGrid))
                }
            }
        }
        
        var rootRenderComplete = false
        var maybeRenderClock: DispatchSemaphore?
        if immediateReceiver != nil {
            let clock = DispatchSemaphore(value: 1)
            maybeRenderClock = clock
            QuickLooper(
                loop: {
                    clock.signal()
                    newRootGrid.sizeGridToContainerNode()
                },
                queue: DispatchQueue(label: "RenderClock", qos: .userInitiated)
            ).runUntil({ rootRenderComplete })
        }
        
        // Kickoff
        renderQueue.async {
            recurseIntoDirectory(rootPath, root: newRootGrid)
            rootRenderComplete = true
        }
        
        
        return newRootGrid.sizeGridToContainerNode()
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
        rootContainerNode.addChildNode(style.grid.rootNode)
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
