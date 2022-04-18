//
//  CodeGridConcurrency.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 11/25/21.
//

import Foundation
import SwiftSyntax
import SceneKit
import SwiftUI

class GridCache {
    typealias CacheValue = (source: CodeGrid, clone: CodeGrid)
    let parser: CodeGridParser
    var cachedGrids = [CodeGrid.ID: CacheValue]()
    var cachedControls = [CodeGrid.ID: CodeGridControl]()
    var cachedFiles = [FileKitPath: CodeGrid.ID]()
    
    private var semaphore = DispatchSemaphore(value: 1)
    func lock()   { semaphore.wait() }
    func unlock() { semaphore.signal() }
    
    init(parser: CodeGridParser) {
        self.parser = parser
    }
    
    func insertGrid(_ key: CodeGrid) {
        cachedGrids[key.id] = (key, key.makeClone())
    }
    
    func insertControl(_ key: CodeGridControl) {
        cachedControls[key.displayGrid.id] = key
    }
    
    func setCache(_ key: FileKitPath) -> CodeGrid {
        let newGrid = parser.renderGrid(key.url) ?? {
            print("Could not render path \(key)")
            return parser.createNewGrid()
        }()
        
        let newClone = newGrid.makeClone()
        
        lock()
        cachedGrids[newGrid.id] = (source: newGrid, clone: newClone)
        cachedFiles[key] = newGrid.id
        unlock()
        return newGrid
    }
    
    func getOrCache(_ key: FileKitPath) -> CodeGrid {
        lock()
        if let gridId = cachedFiles[key],
           let grid = cachedGrids[gridId] {
            unlock()
            return grid.source
        }
        unlock()
        
        return setCache(key)
    }
}
