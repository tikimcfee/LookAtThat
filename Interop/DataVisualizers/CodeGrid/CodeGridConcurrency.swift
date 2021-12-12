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
    var cachedFiles = [FileKitPath: CodeGrid.ID]()
    
    private var semaphore = DispatchSemaphore(value: 1)
    func lock()   { semaphore.wait() }
    func unlock() { semaphore.signal() }
    
    init(parser: CodeGridParser) {
        self.parser = parser
    }
    
    func setCache(_ key: FileKitPath) -> CodeGrid {
        let newGrid = parser.renderGrid(key.url) ?? parser.createNewGrid()
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

class TotalProtonicConcurrency {
    private let cache: GridCache
    private var parser: CodeGridParser
    private var nextWorkerQueue: DispatchQueue { WorkerPool.shared.nextConcurrentWorker() }
    
    init(parser: CodeGridParser,
         cache: GridCache) {
        self.parser = parser
        self.cache = cache
    }
    
    subscript(_ id: CodeGrid.ID) -> CodeGrid? {
        cache.lock()
        let grid = cache.cachedGrids[id]?.source
        cache.unlock()
        return grid
    }
    
    func renderConcurrent(_ path: FileKitPath, _ onRender: @escaping (CodeGrid) -> Void) {
        if path.isDirectory {
            print("<!!> Warning - Trying to create a grid for a directory; are you sure you wanted to do this?")
        }
        nextWorkerQueue.async { [cache] in
            let newGridOrCached = cache.setCache(path)
            onRender(newGridOrCached)
        }
    }
    
    func asyncAccess(_ path: FileKitPath, _ receiver: @escaping (CodeGrid) -> Void) {
        nextWorkerQueue.async { [cache] in
            let found = cache.getOrCache(path)
            receiver(found)
        }
    }
    
    func syncAccess(_ path: FileKitPath) -> CodeGrid {
        nextWorkerQueue.sync { [cache] in
            return cache.getOrCache(path)
        }
    }
}
