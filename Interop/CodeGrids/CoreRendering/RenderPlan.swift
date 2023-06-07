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
    
    let builder: CodeGridGlyphCollectionBuilder
    var statusObject: AppStatus { GlobalInstances.appStatus }
    
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

private extension RenderPlan {
    func doGridLayout() {
        layoutLazyBox()
    }
    
    private func layoutLazyBox() {
        // MARK: - Do grid directory additions
        // TODO: This can probablt happen at cache time
        var orderedParents = OrderedDictionary<URL, MetalLinkNode>()
        
        func makeDefaultParent(for url: URL) -> MetalLinkNode {
            let directoryParent = MetalLinkNode()
            targetParent.add(child: directoryParent)
            targetParent.bindAsVirtualParentOf(directoryParent)
            orderedParents[url] = directoryParent
            return directoryParent
        }
        
        func getParentNode(for url: URL) -> MetalLinkNode {
            let parentURL: URL
            if !url.isDirectory {
                parentURL = url.deletingLastPathComponent()
            } else {
                parentURL = url
            }
            let parent = orderedParents[parentURL]
                ?? makeDefaultParent(for: parentURL)
            return parent
        }
        
        FileBrowser.recursivePaths(rootPath).forEach { url in
            guard !url.isDirectory else { return }
            guard let grid = builder.sharedGridCache.get(url) else { return }
            
            let directoryParent = getParentNode(for: url)
            directoryParent.add(child: grid.rootNode)
        }

        // MARK: - Do final layout
        let xGap = 16.float
        let yGap = 128
        let zGap = 128
        var lastDirectory: MetalLinkNode?
        let layout = DepthLayout()
        
        for (url, directoryParent) in orderedParents {
            let sortedLayoutChildren = directoryParent.children.sorted(
                by: { $0.lengthY < $1.lengthY }
            )
            layout.layoutGrids(sortedLayoutChildren)
            
            let rootDistance = FileBrowser.distanceTo(
                parent: .directory(rootPath),
                from: .directory(url)
            )
            directoryParent.position.y = (-1 * rootDistance * yGap).float
            
            if let lastDirectory = lastDirectory {
                let pushBack = (-1 * rootDistance * zGap).float
                directoryParent
                    .setFront(pushBack)
                    .setLeading(lastDirectory.trailing + xGap)
            }
            
            lastDirectory = directoryParent
        }
        
        for (url, thisParent) in orderedParents {
            let gridBackground = BackgroundQuad(GlobalInstances.defaultLink)
            let gridTopWall = BackgroundQuad(GlobalInstances.defaultLink)
            let gridRightWall = BackgroundQuad(GlobalInstances.defaultLink)
            gridBackground.setColor(LFloat4(0.4, 0.2, 0.2, 0.5))
            gridTopWall.setColor(LFloat4(0.3, 0.2, 0.2, 0.5))
            gridRightWall.setColor(LFloat4(0.2, 0.1, 0.1, 0.5))
            
            let computing = BoundsComputing()
            thisParent.children.forEach { computing.consumeBounds($0.bounds) }
            let bounds = computing.bounds
            let size = BoundsSize(bounds)

            gridBackground.scale.x = size.x / 2.0
            gridBackground.scale.y = size.y / 2.0
            
            gridTopWall.quad.topLeftPos = bounds.min.translated(dY: size.y, dZ: -16.0)
            gridTopWall.quad.topRightPos = bounds.min.translated(dX: size.x, dY: size.y, dZ: -16.0)
            gridTopWall.quad.botLeftPos = bounds.min.translated(dY:size.y, dZ: size.z)
            gridTopWall.quad.botRightPos = bounds.max
            
            gridRightWall.quad.topLeftPos = bounds.max.translated(dZ: -size.z - 16.0)
            gridRightWall.quad.topRightPos = bounds.max
            gridRightWall.quad.botLeftPos = bounds.min.translated(dX: size.x, dZ: -16.0)
            gridRightWall.quad.botRightPos = bounds.max.translated(dY: -size.y)
            
            gridBackground
                .setLeading(bounds.min.x)
                .setTop(bounds.max.y)
                .setFront(bounds.min.z - 16.0)
            
            thisParent.add(child: gridBackground)
            thisParent.add(child: gridTopWall)
            thisParent.add(child: gridRightWall)
            
            var lineParent = url.deletingLastPathComponent()
            var thisParentParent: MetalLinkNode?
            while lineParent.pathComponents.count > 1, thisParentParent == nil {
                thisParentParent = orderedParents[lineParent]
                lineParent.deleteLastPathComponent()
            }
            
            if let thisParentParent {
                let line = MetalLinkLine(GlobalInstances.defaultLink)
                line.setColor(LFloat4(1.0, 0.0, 0.1, 1.0))
                line.appendSegment(
                    about: thisParentParent.position
                )
                line.appendSegment(
                    about: LFloat3(
                        x: thisParent.position.x,
                        y: thisParentParent.position.y,
                        z: thisParentParent.position.z
                    )
                )
                line.appendSegment(
                    about: LFloat3(
                        x: thisParent.position.x - 10.0,
                        y: thisParent.position.y + 10.0,
                        z: thisParentParent.position.z - 10.0
                    )
                )
                line.appendSegment(
                    about: thisParent.position
                )
                thisParent.parent?.add(child: line)
            }
        }
    }
}

private extension RenderPlan {
    func cacheGrids() {
        statusObject.update {
            $0.totalValue += 1 // pretend there's at least one unfinished task
            $0.message = "Starting grid cache..."
        }
        
        var worker: DispatchQueue { WorkerPool.shared.nextWorker() }
        let dispatchGroup = DispatchGroup()
        
        if rootPath.isDirectory {
            recursiveCache()
        } else {
            rootCache()
        }
        
        dispatchGroup.wait()
        
        func rootCache() {
            launchGridBuild(rootPath)
        }
        
        func recursiveCache() {
            FileBrowser.recursivePaths(rootPath)
                .filter { !$0.isDirectory && FileBrowser.isSupportedFileType($0) }
                .forEach { childPath in
                    launchGridBuild(childPath)
                }
        }
        
        
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
                
                builder.sharedGridCache.cachedFiles[childPath] = grid.id
                
                statusObject.update {
                    $0.currentValue += 1
                    $0.detail = "File Complete: \(childPath.lastPathComponent)"
                }
                
                hoverController.attachPickingStream(to: grid)
                
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
