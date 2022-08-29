//
//  CodeGridConcurrentRenderer.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 4/16/22.
//

import Foundation

class ConcurrentGridRenderer {
    private let cache: GridCache
    var nextWorkerQueue: DispatchQueue { WorkerPool.shared.nextWorker() }
    
    init(cache: GridCache) {
        self.cache = cache
    }
    
    subscript(_ id: CodeGrid.ID) -> CodeGrid? {
        return cache.cachedGrids[id]
    }
    
    func renderConcurrent(_ path: URL, _ onRender: @escaping (CodeGrid) -> Void) {
        if path.isDirectory {
            print("<!!> Warning - Trying to create a grid for a directory; are you sure you wanted to do this?")
        }
        nextWorkerQueue.async { [cache] in
            let newGridOrCached = cache.setCache(path)
            onRender(newGridOrCached)
        }
    }
    
    func asyncAccess(_ path: URL, _ receiver: @escaping (CodeGrid) -> Void) {
        nextWorkerQueue.async { [cache] in
            let foundGrid = cache.getOrCache(path)
            receiver(foundGrid)
        }
    }
    
    func syncAccess(_ path: URL) -> CodeGrid {
        nextWorkerQueue.sync { [cache] in
            return cache.getOrCache(path)
        }
    }
}
