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
        var directoryGroups = [CodeGrid: CodeGridGroup]()
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
                cacheGrids()
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
//        layoutWide()
//        layoutLazyBox()
        layoutFullGood()
    }
    
    private func layoutFullGood() {
        let rootGrid = self.builder.sharedGridCache.setCache(rootPath)
            .withSourcePath(rootPath)
            .withFileName(rootPath.fileName)
            .applyName()
        let rootGroup = CodeGridGroup(globalRootGrid: rootGrid)
        targetParent.add(child: rootGrid.rootNode)
        
        state.orderedParents[rootPath] = rootGrid
        state.directoryGroups[rootGrid] = rootGroup
        
        /*
         Adding groups / directories is weird.
         If we find a parent group (root or otherwise), we want to parent this group to the other one.
         However, this misses the sibling relationship. This results in all siblings and 'subdirectories'
         laying out identically. So what do we want?
         If I found a parent that already has children, I'm a sibling, so add me differently.
         If I'm the first one, I should 'set the standard' and be placed in some offset that implies I'm a subdirectory.
         So:
         a/b/c    | siblings(b)
         a/b/c/d  |   siblings(c)
         a/b/c/e  |   siblings(c)
         a/b/c/f  |   siblings(c)
         a/b/g    | siblings(b)
         a/b/g/h  |   siblings(g)
         a/b/g/i  |   siblings(g)
         a/b/g/j  |   siblings(g)
         a/b/g/k  |   siblings(g)
         a/b/m    | siblings(b)
         a/b/n    | siblings(b)
         a/b/o    | siblings(b)
         a/b/p    | siblings(b)
         
         I dunno if that helped. Ok, so files go left-right. That's decided.
         
         If I'm a directory, find my parent
             if I'm the first one..
                 put me underneath the tallest grid, align my leading to my parent
             if I'm *not* the first one..
                 put me trailing the last sibling group
        */
        
        // Attach grids to parent groups
        FileBrowser.recursivePaths(rootPath).forEach { childPath in
            let grid = builder.sharedGridCache.get(childPath)
            if let grid, !childPath.isDirectory {
                // Adding files is kinda easy - just add it to the parent and let it sort out position
                if let parent = firstParentGroupOf(target: childPath) {
                    grid.applyName()
                    parent.addChildGrid(grid)
                } else {
                    print("-- \(childPath) missing parent for grid...")
                }
            } else if let grid, let group = state.directoryGroups[grid] {
                if let parent = firstParentGroupOf(target: childPath) {
                    print("Adding \(childPath) to \(parent.globalRootGrid.sourcePath!)")
                    group.globalRootGrid.applyName()
                    parent.addChildGroup(group)
                } else {
                    print("-- \(childPath) missing parent for directory...")
                }
            } else {
                print("[!!!] not rendering \(childPath)")
            }
        }
        
        rootGroup.applyAllConstraints()
//        addParentWalls()
    }
    
    
    func firstParentGroupOf(target: URL) -> CodeGridGroup? {
        var parentURL = target.deletingLastPathComponent()
        var parentGrid: CodeGrid?
        var parentGroup: CodeGridGroup?
        while parentURL.pathComponents.count > 1, parentGroup == nil {
            parentGrid = state.orderedParents[parentURL]
            parentGroup = parentGrid.map { state.directoryGroups[$0] } ?? nil
            parentURL.deleteLastPathComponent()
        }
        return parentGroup
    }
    
    func getDirectoryBasedPosition(
        of url: URL,
        xGap: Int = 16,
        yGap: Int = 32,
        zGap: Int = 24
    ) -> LFloat3 {
        let rootDistance = FileBrowser.distanceTo(
            parent: .directory(rootPath),
            from: .directory(url)
        )
        return LFloat3(
            x: 0.0,
            y: (-1 * rootDistance * yGap).float,
            z: (1 * rootDistance * zGap).float
        )
    }
    
    func addParentWalls() {
        for (grid, group) in state.directoryGroups {
//            let gridBackground = BackgroundQuad(GlobalInstances.defaultLink)
//            let gridTopWall = BackgroundQuad(GlobalInstances.defaultLink)
//            let gridRightWall = BackgroundQuad(GlobalInstances.defaultLink)
//            gridBackground.setColor(LFloat4(0.4, 0.2, 0.2, 0.5))
//            gridTopWall.setColor(LFloat4(0.3, 0.2, 0.2, 0.5))
//            gridRightWall.setColor(LFloat4(0.2, 0.1, 0.1, 0.5))
//            grid.rootNode.add(child: gridBackground)
////            grid.rootNode.add(child: gridTopWall)
////            grid.rootNode.add(child: gridRightWall)
//
//            var rect: Bounds { group.globalRootGrid.rectPos }
//            var size: LFloat3 { BoundsSize(rect) }
//
//            gridBackground.size = LFloat2(x: size.x, y: size.y)
//            gridBackground
//                .setLeading(rect.min.x)
//                .setTop(rect.max.y)
//                .setFront(rect.min.z)
            group.globalRootGrid.updateBackground()
        }
    }
}

private extension RenderPlan {
    func cacheGrids() {
        var worker: DispatchQueue { WorkerPool.shared.nextWorker() }
        statusObject.update {
            $0.totalValue += 1 // pretend there's at least one unfinished task
            $0.message = "Starting grid cache..."
        }
        
        let dispatchGroup = DispatchGroup()
        
        if rootPath.isDirectory {
            FileBrowser.recursivePaths(rootPath).forEach { childPath in
                if FileBrowser.isSupportedFileType(childPath) {
                    launchGridBuild(childPath)
                }
                else if childPath.isDirectory {
                    let childDirectoryGrid = builder.sharedGridCache
                        .setCache(childPath)
                        .withSourcePath(childPath)
                        .withFileName(childPath.fileName)
                    
                    state.orderedParents[childPath] = childDirectoryGrid
                    state.directoryGroups[childDirectoryGrid] = CodeGridGroup(globalRootGrid: childDirectoryGrid)
                }
            }
        } else {
            launchGridBuild(rootPath)
        }
        dispatchGroup.wait()

        
        func launchGridBuild(_ childPath: URL) {
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
                    .translated(dZ: 8.0)
                
                builder.sharedGridCache.cachedFiles[childPath] = grid.id
                hoverController.attachPickingStream(to: grid)

                statusObject.update {
                    $0.currentValue += 1
                    $0.detail = "File Complete: \(childPath.lastPathComponent)"
                }
                dispatchGroup.leave()
            }
        }
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
