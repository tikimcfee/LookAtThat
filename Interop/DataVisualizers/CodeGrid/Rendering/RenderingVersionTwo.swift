//
//  RenderingVersionTwo.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 11/25/21.
//

import Foundation
import SwiftSyntax
import SceneKit
import SwiftUI

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
