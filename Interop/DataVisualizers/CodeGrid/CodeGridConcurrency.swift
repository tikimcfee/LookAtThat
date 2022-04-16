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
    var nextWorkerQueue: DispatchQueue { WorkerPool.shared.nextConcurrentWorker() }
    
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
            let foundGrid = cache.getOrCache(path)
            self.waitForElements(foundGrid) {
                receiver(foundGrid)
            }
        }
    }
    
    func syncAccess(_ path: FileKitPath) -> CodeGrid {
        nextWorkerQueue.sync { [cache] in
            return cache.getOrCache(path)
        }
    }
    
    
    // I truly dislike this whole function but here's why it's here:
    // The way I'm doing things, as of this commit, the replacement of the
    // original glyph root layer with a cloned copy ends up with the clones
    // not immediately having geometry elements. Originally I thought this
    // was a bug, then some kind of 'hidden' value. However, I finally ran
    // it live and saw it working correctly. It turns out _something else_
    // is happening during that clone, and to that clone, which ends up
    // filling the clone's geometry elements later in time.
    //
    // I have no idea what that is.
    //
    // However, more random experiments found that it was somewhat safe to
    // wait for these cloned copies to actually show up by themselves.
    // Additional testing shows there's a correlation to the overall number
    // of nodes being cloned with how long it takes for those clones to appear
    // in the elements container.
    //
    // This function just spins until the element set is not empty. So far, this
    // has not failed. Which it likely will, and very soon and suddenly.
    func waitForElements(_ grid: CodeGrid, _ done: @escaping () -> Void) {
        var waitCount = 0
        let waitUnit = DispatchTimeInterval.milliseconds(1)
        var isNotEmpty: Bool { grid.rootGlyphsNode.geometry?.elements.isEmpty == false }
        
        func check() {
            waitCount += 1
            guard isNotEmpty else { return }
            print("- Elements ready for \(grid.fileName), t ~ \(waitCount) \(waitUnit)")
            grid.sizeGridToContainerNode()
            done()
        }
        
        QuickLooper(
            interval: waitUnit,
            loop: { /* use runUntil as check and return to avoid race on callback and flag */ },
            queue: nextWorkerQueue
        ).runUntil {
            check()
            return isNotEmpty
        }
    }
}
