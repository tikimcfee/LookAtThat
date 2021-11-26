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
    
    override func make(_ key: FileKitPath, _ store: inout [FileKitPath : CodeGrid]) -> CodeGrid {
        let newGrid = parser.renderGrid(key.url) ?? parser.createNewGrid()
        cachedGrids[newGrid.id] = newGrid
        return newGrid
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
    
    func concurrentRenderAccess(_ path: FileKitPath, _ onRender: @escaping (CodeGrid) -> Void) {
        if path.isDirectory {
            print("<!!> Warning - Trying to create a grid for a directory; are you sure you wanted to do this?")
        }
        nextWorkerQueue.async { [cache] in
            let newGridOrCached = cache[path]
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
