//
//  RenderPlan.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 5/21/22.
//

import SwiftSyntax
import Foundation
import OrderedCollections
import MetalLink
import BitHandling

struct RenderPlan {
    let rootPath: URL
    let queue: DispatchQueue
    
    var statusObject: AppStatus { GlobalInstances.appStatus }
    let builder: CodeGridGlyphCollectionBuilder
    
    let editor: WorldGridEditor
    let focus: WorldGridFocusController
    let hoverController: MetalLinkHoverController
    
    let targetParent = MetalLinkNode()
    
    class State {
        var orderedParents = OrderedDictionary<URL, CodeGrid>()
        
        /// Maps the file or directory URL to its contained.
        /// It's either the parent, or one of its children.
//        var directoryGroups = [URL: CodeGridGroup]()
        var directoryGroups = ConcurrentDictionary<URL, CodeGridGroup>()
    }
    var state = State()

    
    let mode: Mode
    enum Mode {
        case cacheOnly
        case layoutOnly
        case cacheAndLayout
    }
    
    func startRender(_ onComplete: @escaping () -> Void = { }) {
        queue.async {
            statusObject.resetProgress()
            
            WatchWrap.startTimer("\(rootPath.fileName)")
            renderTaskForMode()
            WatchWrap.stopTimer("\(rootPath.fileName)")
            
            statusObject.update {
                $0.message = "Render complete!"
                $0.currentValue = statusObject.progress.totalValue
            }
            
            onComplete()
        }
    }
    
    private var renderTaskForMode: () -> Void {
        switch mode {
        case .cacheAndLayout:
            return {
                targetParent.pausedInvalidate = true
                cacheGrids()
                targetParent.pausedInvalidate = false
                
                doGridLayout()
            }
        case .cacheOnly:
            return {
                cacheGrids()
            }
        case .layoutOnly:
            return {
                doGridLayout()
            }
        }
    }
}

private extension RenderPlan {
    func doGridLayout() {
        justShowMeCodePlease()
    }
    
    func justShowMeCodePlease() {
        guard rootPath.isDirectory else { return }
        state.directoryGroups[rootPath]?.applyAllConstraints()
        
//        targetParent.pausedInvalidate = true
//        state.directoryGroups[rootPath]?.addLines(targetParent)
//        targetParent.pausedInvalidate = false
    }
}

private extension RenderPlan {
    func cacheGrids() {
        statusObject.update {
            $0.totalValue += 1 // pretend there's at least one unfinished task
            $0.message = "Starting grid cache..."
        }
        
        guard rootPath.isDirectory else {
            let rootGrid = launchFileGridBuildSync(rootPath)
            targetParent.add(child: rootGrid.rootNode)
            return
        }
        
        let dispatchGroup = DispatchGroup()
        
        let rootGrid = builder.sharedGridCache
            .setCache(rootPath)
            .withSourcePath(rootPath)
            .withFileName(rootPath.fileName)
            .applyName()
        
        rootGrid.removeBackground()
        
        let group = CodeGridGroup(globalRootGrid: rootGrid)
        state.directoryGroups[rootPath] = group
        targetParent.add(child: rootGrid.rootNode)
        
        FileBrowser.recursivePaths(rootPath).forEach { childPath in
            if FileBrowser.isSupportedFileType(childPath) {
                launchFileGridBuild(dispatchGroup, childPath)
            } else if childPath.isDirectory {
                launchDirectoryGridBuild(dispatchGroup, childPath)
            } else {
                print("Skipping file: \(childPath.fileName)")
            }
        }
        dispatchGroup.wait()
        
        FileBrowser.recursivePaths(rootPath).forEach { childPath in
            if FileBrowser.isSupportedFileType(childPath) {
                let grid = builder
                    .sharedGridCache
                    .get(childPath)!
                
                let group = state
                    .directoryGroups[childPath.deletingLastPathComponent()]!
                
                group.globalRootGrid.rootNode.pausedInvalidate = true
                group.addChildGrid(grid)
                group.globalRootGrid.rootNode.pausedInvalidate = false
            }
        }
    }
    
    func launchDirectoryGridBuild(
        _ dispatchGroup: DispatchGroup,
        _ childPath: URL
    ) {
        var worker: DispatchQueue { WorkerPool.shared.nextWorker() }
        
        dispatchGroup.enter()
        worker.async {
            let grid = builder.sharedGridCache
                .setCache(childPath)
                .withSourcePath(childPath)
                .withFileName(childPath.fileName)
                .applyName()
            
            grid.removeBackground()
            let group = CodeGridGroup(globalRootGrid: grid)
            state.directoryGroups[childPath] = group
            
            if let parent = state.directoryGroups[childPath.deletingLastPathComponent()] {
                parent.globalRootGrid.rootNode.pausedInvalidate = true
                parent.addChildGroup(group)
                parent.globalRootGrid.rootNode.pausedInvalidate = false
            }
            
            dispatchGroup.leave()
        }
    }
    
    func launchFileGridBuild(
        _ dispatchGroup: DispatchGroup,
        _ childPath: URL
    ) {
        var worker: DispatchQueue { WorkerPool.shared.nextWorker() }
        
        dispatchGroup.enter()
        statusObject.update {
            $0.totalValue += 1
            $0.detail = "File: \(childPath.lastPathComponent)"
        }
        
        worker.async {
            let grid = builder
                .createConsumerForNewGrid()
                .consume(url: childPath)
                .withFileName(childPath.lastPathComponent)
                .withSourcePath(childPath)
                .applyName()
            
            builder.sharedGridCache.cachedFiles[childPath] = grid.id
            hoverController.attachPickingStream(to: grid)
            
            statusObject.update {
                $0.currentValue += 1
                $0.detail = "File Complete: \(childPath.lastPathComponent)"
            }
            dispatchGroup.leave()
        }
    }
    
    @discardableResult
    func launchFileGridBuildSync(
        _ childPath: URL
    ) -> CodeGrid {
        var worker: DispatchQueue { WorkerPool.shared.nextWorker() }
        
        statusObject.update {
            $0.totalValue += 1
            $0.detail = "File: \(childPath.lastPathComponent)"
        }
        
        let codeGrid: CodeGrid = worker.sync {
            let grid = builder
                .createConsumerForNewGrid()
                .consume(url: childPath)
                .withFileName(childPath.lastPathComponent)
                .withSourcePath(childPath)
                .applyName()
            
            builder.sharedGridCache.cachedFiles[childPath] = grid.id
            hoverController.attachPickingStream(to: grid)
            
            statusObject.update {
                $0.currentValue += 1
                $0.detail = "File Complete: \(childPath.lastPathComponent)"
            }
            
            return grid
        }
        return codeGrid
    }
}

class WatchWrap {
    static let stopwatch = Stopwatch(running: false)
    
    static func startTimer(_ name: String) {
        print("[* StopWatch *] Starting \(name)")
        stopwatch.start()
        
    }
    static func stopTimer(_ name: String) {
        defer { stopwatch.reset() }
        stopwatch.stop()
        let time = Self.stopwatch.elapsedTimeString()
        print("[* Stopwatch *] Time for \(name): \(time)")
    }
}

// MARK: - Focus Style

extension LFloat3 {
    var magnitude: Float {
        sqrt(x * x + y * y + z * z)
    }
    
    var normalized: LFloat3 {
        let magnitude = magnitude
        return magnitude == 0
            ? .zero
            : self / magnitude
    }
    
    mutating func normalize() -> LFloat3 {
        self = self / magnitude
        return self
    }
}
