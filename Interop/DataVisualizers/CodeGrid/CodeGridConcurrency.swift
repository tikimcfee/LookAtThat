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

class GridCache: LockingCache<FileKitPath, CodeGrid> {
    let parser: CodeGridParser
    var cachedGrids = [CodeGrid.ID: CodeGrid]()
    
    init(parser: CodeGridParser) {
        self.parser = parser
    }
    
    func setCache(_ key: FileKitPath) -> CodeGrid{
        let newGrid = parser.renderGrid(key.url) ?? parser.createNewGrid()
        lockAndDo { cache in
            cache[key] = newGrid
            cachedGrids[newGrid.id] = newGrid
        }
        return newGrid
    }
    
    override func make(_ key: FileKitPath, _ store: inout [FileKitPath : CodeGrid]) -> CodeGrid {
        print("Cache miss: \(key.fileName)")
        let newGrid = parser.renderGrid(key.url) ?? parser.createNewGrid()
        cachedGrids[newGrid.id] = newGrid
        return newGrid
    }
}

class TotalProtonicConcurrency {
    private let cache: GridCache
    private var parser: CodeGridParser
    private var nextWorkerQueue: DispatchQueue { WorkerPool.shared.nextWorker() }
    
    init(parser: CodeGridParser,
         cache: GridCache) {
        self.parser = parser
        self.cache = cache
    }
    
    subscript(_ id: CodeGrid.ID) -> CodeGrid? {
        var grid: CodeGrid?
        cache.lockAndDo { _ in
            grid = cache.cachedGrids[id]
        }
        return grid
    }
    
    func concurrentRenderAccess(_ path: FileKitPath, _ onRender: @escaping (CodeGrid) -> Void) {
        if path.isDirectory {
            print("<!!> Warning - Trying to create a grid for a directory; are you sure you wanted to do this?")
        }
        nextWorkerQueue.async { [cache] in
//            let newGridOrCached = cache[path]
            let newGridOrCached = cache.setCache(path)
            onRender(newGridOrCached)
        }
    }
    
    func syncAccess(_ path: FileKitPath) -> CodeGrid {
        nextWorkerQueue.sync { [cache] in
            let newGridOrCached = cache[path]
            return newGridOrCached
        }
    }
}
