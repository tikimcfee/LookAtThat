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
        layoutCoicles()
    }
    
    func layoutCoicles() {
        BSPLayout().layout(root: targetParent)
    }
    
    func addParentWalls() {
//        for (grid, group) in state.directoryGroups {
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
//            group.globalRootGrid.updateBackground()
//        }
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
            let rootGrid = builder.sharedGridCache
                .setCache(rootPath)
                .withSourcePath(rootPath)
                .withFileName(rootPath.fileName)
                .applyName()
            targetParent
                .add(child: rootGrid.rootNode)
            
            FileBrowser.recursivePaths(rootPath).forEach { childPath in
                if FileBrowser.isSupportedFileType(childPath) {
                    launchGridBuild(childPath)
                }
                else if childPath.isDirectory {
                    let childDirectoryGrid = builder.sharedGridCache
                        .setCache(childPath)
                        .withSourcePath(childPath)
                        .withFileName(childPath.fileName)
                        .applyName()
                    
                    if let parent = builder.sharedGridCache.get(childPath.deletingLastPathComponent()) {
                        parent.addChildGrid(childDirectoryGrid)
                    }
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
                    .applyName()
                
                builder.sharedGridCache.cachedFiles[childPath] = grid.id
                hoverController.attachPickingStream(to: grid)
                
                if let parent = builder.sharedGridCache.get(childPath.deletingLastPathComponent()) {
                    parent.addChildGrid(grid)
                }

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
