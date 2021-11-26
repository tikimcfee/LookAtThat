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
    
    var cameraNode: SCNNode?
    
    private let renderQueue = DispatchQueue(label: "RenderClock", qos: .userInitiated)
    
    private let rootGridColor  = NSUIColor(displayP3Red: 0.0, green: 0.4, blue: 0.6, alpha: 0.2)
    private let directoryColor = NSUIColor(displayP3Red: 0.2, green: 0.6, blue: 0.8, alpha: 0.2)
    
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
    
    lazy var concurrency: TotalProtonicConcurrency = {
        let cache = TotalProtonicConcurrency(
            parser: self
        )
        return cache
    }()
}

// MARK: - Rendering strategies
class RecurseState {
    let snapping = WorldGridSnapping()
}
extension CodeGridParser {
    private func kickoffRecursiveRender(
        _ rootDirectory: FileKitPath,
        _ depth: Int,
        _ state: RecurseState
    ) -> CodeGrid {
        var fileStack: [FileKitPath] = []
        var directoryStack: [FileKitPath] = []
        
#if os(macOS)
        let alpha = rootGridColor.alphaComponent * VectorFloat(depth)
        let rootDirectoryGrid = createNewGrid().backgroundColor(rootGridColor.withAlphaComponent(alpha))
#elseif os(iOS)
        let alpha = rootGridColor.cgColor.alpha * CGFloat(depth)
        let rootDirectoryGrid = createNewGrid().backgroundColor(rootGridColor.withAlphaComponent(alpha))
#endif
        
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
//            print("File *** \(last.url.lastPathComponent)")
            let newGrid = concurrency.syncAccess(last)
            newGrid.rootNode.position.z = 4.0
            if let lastGrid = lastDirectChildGrid {
                state.snapping.connectWithInverses(sourceGrid: lastGrid, to: [.right(newGrid)])
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
        var maxHeight = lastDirectChildGrid?.rootNode.lengthY ?? VectorFloat(0.0)
        var nexRowStartPosition = SCNVector3Zero
        if let start = lastDirectChildGrid {
            state.snapping.iterateOver(start, direction: .left) { grid in
                maxHeight = max(maxHeight, grid.rootNode.lengthY)
            }
            nexRowStartPosition = nexRowStartPosition.translated(dY: -maxHeight - 8.0)
        }
        
        nexRowStartPosition = nexRowStartPosition.translated(dZ: 32.0 * VectorFloat(depth))
        while let last = directoryStack.popLast() {
//            print("Dir <--> \(last.url.lastPathComponent)")
            let childDirectory = kickoffRecursiveRender(last, depth + 1, state)
            
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
    
    func __versionThree_RenderConcurrent(
        _ rootPath: FileKitPath,
        _ onLoadComplete: ((CodeGrid) -> Void)? = nil
    ) {
        // Two passes: render all the source, then position it all again with the same cache.
        renderQueue.async {
            // first pass: precache grids
            let dispatchGroup = DispatchGroup()
            print("* Starting grid precache...")
            FileBrowser.recursivePaths(rootPath).forEach { childPath in
                guard !childPath.isDirectory else {
//                    print("Skip directory: \(childPath)")
                    return
                }
                dispatchGroup.enter()
                self.concurrency.concurrentRenderAccess(childPath) { newGrid in
//                    print("Rendered \(childPath)")
                    dispatchGroup.leave()
                }
            }
            dispatchGroup.wait()
            print("* Precache complete.")
            
            // second pass: position grids
            print("* Starting layout...")
            let newRootGrid = self.kickoffRecursiveRender(rootPath, 1, RecurseState())
            print("* Layout complete.")
            onLoadComplete?(newRootGrid)
        }
    }
}

extension CodeGridParser {
    func __versionTwo__RenderPathAsRoot(
        _ rootPath: FileKitPath,
        _ onLoadComplete: ((CodeGrid) -> Void)? = nil
    ) {
        let snapping = WorldGridSnapping()
        
        func makeGridForDirectory2(_ rootDirectory: FileKitPath, _ depth: Int) -> CodeGrid {
            #if os(macOS)
            let alpha = rootGridColor.alphaComponent * VectorFloat(depth)
            #elseif os(iOS)
            let alpha = rootGridColor.cgColor.alpha * CGFloat(depth)
            #endif
            
            let rootDirectoryGrid = createNewGrid().backgroundColor(
                rootGridColor.withAlphaComponent(alpha)
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
//                print("File *** \(last.url.lastPathComponent)")
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
            var maxHeight = lastDirectChildGrid?.rootNode.lengthY ?? VectorFloat(0.0)
            var nexRowStartPosition = SCNVector3Zero
            if let start = lastDirectChildGrid {
                snapping.iterateOver(start, direction: .left) { grid in
                    maxHeight = max(maxHeight, grid.rootNode.lengthY)
                }
                nexRowStartPosition = nexRowStartPosition.translated(dY: -maxHeight - 8.0)
            }
            
            nexRowStartPosition = nexRowStartPosition.translated(dZ: 32.0 * VectorFloat(depth))
            while let last = directoryStack.popLast() {
//                print("Dir <--> \(last.url.lastPathComponent)")
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
            onLoadComplete?(newRootGrid)
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
