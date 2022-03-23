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
    #if os(OSX)
    static let stopwatch = Stopwatch(running: false)
    static func startTimer() {
        print("* Starting grid cache...")
        stopwatch.start()
    }
    static func stopTimer() {
        defer { stopwatch.reset() }
        stopwatch.stop()
        let time = Self.stopwatch.elapsedTimeString()
        print("* Cache complete. Rendering time: \(time)")
    }
    #else
    static func startTimer() { }
    static func stopTimer() { }
    #endif
    
    func cacheConcurrent(
        _ rootPath: FileKitPath,
        _ onLoadComplete: (() -> Void)? = nil
    ) {
        renderQueue.async { [concurrency] in
            let dispatchGroup = DispatchGroup()
            Self.startTimer()
            
            FileBrowser.recursivePaths(rootPath)
                .filter { !$0.isDirectory }
                .forEach { childPath in
                    dispatchGroup.enter()
                    concurrency.renderConcurrent(childPath) { _ in
                        dispatchGroup.leave()
                    }
                }
            
            dispatchGroup.wait()
            Self.stopTimer()
            
            onLoadComplete?()
        }
    }
    
    func __versionThree_RenderConcurrent(
        _ rootPath: FileKitPath,
        _ onLoadComplete: ((CodeGrid) -> Void)? = nil
    ) {
        // Two passes: render all the source, then position it all again with the same cache.
        renderQueue.async {
            let dispatchGroup = DispatchGroup()
            Self.startTimer()
            
            FileBrowser.recursivePaths(rootPath)
                .filter { !$0.isDirectory }
                .forEach { childPath in
                    dispatchGroup.enter()
                    self.concurrency.asyncAccess(childPath) { _ in
                        dispatchGroup.leave()
                    }
                }
            
            dispatchGroup.wait()
            let newRootGrid = self.kickoffRecursiveRender(rootPath, 1, RecurseState())
            Self.stopTimer()
            
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
        let color = rootGridColor.withAlphaComponent(alpha)
        let rootDirectoryGrid = createNewGrid().backgroundColor(color)
#elseif os(iOS)
        let alpha = rootGridColor.cgColor.alpha * CGFloat(depth)
        let color = rootGridColor.withAlphaComponent(alpha)
        let rootDirectoryGrid = createNewGrid().applying {
            $0.transparentBackgroundColor(color)
        }
#endif
        gridCache.insertGrid(rootDirectoryGrid)
        
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
                state.snapping.connectWithInverses(sourceGrid: lastGrid, to: .right(newGrid))
                newGrid.measures.alignedToTrailingOf(lastGrid, pad: 4.0)
            }
            lastDirectChildGrid = newGrid
            rootDirectoryGrid.rootNode.addChildNode(newGrid.rootNode)
            
            let fileName = makeFileNameGrid(last.url.lastPathComponent)
            fileName.rootNode.position = SCNVector3Zero.translated(
                dY: fileName.measures.lengthY + 2.0,
                dZ: 4.0
            )
            newGrid.rootNode.addChildNode(fileName.rootNode)
        }
        
        // all files haves been rendered for this directory; move focus back to the left-most
        var maxHeight = lastDirectChildGrid?.measures.lengthY ?? VectorFloat(0.0)
        var nexRowStartPosition = SCNVector3Zero
        if let start = lastDirectChildGrid {
            state.snapping.iterateOver(start, direction: .left) { _, grid, _ in
                maxHeight = max(maxHeight, grid.measures.lengthY)
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
                dY: fileName.measures.lengthY * 6 + 2.0,
                dZ: 8.0
            )
            fileName.rootNode.scale = SCNVector3(x: 3.0, y: 3.0, z: 1.0)
            childDirectory.rootNode.addChildNode(fileName.rootNode)
            
            nexRowStartPosition = nexRowStartPosition.translated(
                dX: childDirectory.measures.lengthX + 8
            )
            
            gridCache.insertGrid(fileName)
        }
        
        return rootDirectoryGrid.sizeGridToContainerNode()
    }
}
