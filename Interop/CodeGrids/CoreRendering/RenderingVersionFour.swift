//
//  RenderingVersionFour.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 12/14/21.
//

import Foundation

import Foundation
import SwiftSyntax
import SceneKit
import SwiftUI

extension CodeGridParser {
    func __versionFour_RenderConcurrent(
        _ rootPath: URL,
        _ onLoadComplete: ((CodeGrid) -> Void)? = nil
    ) {
        
        // Two passes: render all the source, then position it all again with the same cache.
        renderQueue.async {
            Self.startTimer()
            self.doRenderV4(rootPath, onLoadComplete)
            Self.stopTimer()
        }
    }
    
    private func doRenderV4(
        _ rootPath: URL,
        _ onLoadComplete: ((CodeGrid) -> Void)? = nil
    ) {
        let rootGridColor  = NSUIColor(displayP3Red: 0.0, green: 0.4, blue: 0.6, alpha: 0.2)
        let directoryColor = NSUIColor(displayP3Red: 0.2, green: 0.6, blue: 0.8, alpha: 0.2)
        
        var allDirectoryPaths = [URL]()
        allDirectoryPaths.append(rootPath)
        let allGridFiles = FileBrowser.recursivePaths(rootPath)
            .filter { path in
                if !path.isDirectory {
                    return true
                } else {
                    allDirectoryPaths.append(path)
                    return false
                }
            }
            .reduce(into: [URL: CodeGrid]()) { result, path in
                result[path] = self.concurrency.syncAccess(path)
            }
        
        let snapping = WorldGridSnapping()
        let rootContainerGrid: CodeGrid = createNewGrid()
            .backgroundColor(rootGridColor)
        
        /// Reg1: Last file grid
        /// Reg2: Last directory grid
        
        allDirectoryPaths.sort(by: { $0.children().count > $1.children().count })
        for directory in allDirectoryPaths {
            print(directory)
            let directoryGrid = createNewGrid()
                .backgroundColor(directoryColor)
                .asChildOf(rootContainerGrid)
                .translated(dZ: 8.0)
            
            FileBrowser.directChildren(directory)
                .filter { !$0.isDirectory }
                .compactMap { allGridFiles[$0] }
                .sorted(by: { $0.measures.lengthY > $1.measures.lengthY })
                .forEach
            { grid in
                if let lastInDirectory = snapping.gridReg1 {
                    grid.measures.setTop(lastInDirectory.measures.top)
                    grid.measures.setLeading(lastInDirectory.measures.trailing + 8.0)
                    grid.measures.setFront(lastInDirectory.measures.front)
                } else {
                    grid.measures.setTop(directoryGrid.measures.top)
                    grid.measures.setLeading(directoryGrid.measures.leading)
                    grid.measures.setBack(directoryGrid.measures.front)
                }
                grid.asChildOf(directoryGrid)
                snapping.gridReg1 = grid
            }
            snapping.gridReg1 = nil
            
            directoryGrid.sizeGridToContainerNode(pad: 8.0)
            if let lastDirectory = snapping.gridReg2 {
                directoryGrid.measures.setLeading(lastDirectory.measures.leading)
                directoryGrid.measures.setTop(lastDirectory.measures.top)
                directoryGrid.measures.setBack(lastDirectory.measures.front + 64.0)
            } else {
                directoryGrid.measures.setLeading(rootContainerGrid.measures.leading)
                directoryGrid.measures.setTop(rootContainerGrid.measures.top)
                directoryGrid.measures.setBack(rootContainerGrid.measures.front)
            }
            snapping.gridReg2 = directoryGrid
        }
        
        rootContainerGrid.sizeGridToContainerNode(pad: 32.0)
        onLoadComplete?(rootContainerGrid)
    }
}
