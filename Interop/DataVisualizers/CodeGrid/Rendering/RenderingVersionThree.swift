//
//  RenderingVersionThree.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 11/25/21.
//

import Foundation
import SwiftSyntax
import SceneKit
import SwiftUI

extension CodeGridParser {
    func __versionThree_RenderConcurrent(
        _ rootPath: FileKitPath,
        _ onLoadComplete: ((CodeGrid) -> Void)? = nil
    ) {
        // Two passes: render all the source, then position it all again with the same cache.
        renderQueue.async {
            let stopwatch = Stopwatch(running: true)
            
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
            
            stopwatch.stop()
            let time = stopwatch.elapsedTimeString()
            print("Rendering time for \(rootPath.fileName): \(time)")
            onLoadComplete?(newRootGrid)
        }
    }
    
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
}
