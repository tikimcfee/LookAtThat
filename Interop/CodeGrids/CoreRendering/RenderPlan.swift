//
//  RenderPlan.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 5/21/22.
//

import SwiftSyntax
import Foundation
import OrderedCollections

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
            let parent = orderedParents[parentURL] ?? makeDefaultParent(for: parentURL)
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
        
//        RadialLayout().layoutGrids(Array(orderedParents.values))
        // Test that each directory is properly parented with this cockamamie scheme
//        for directoryParent in targetParent.children {
//            var counter = 0.float + Float.random(in: 0..<(Float.pi * 2))
//            QuickLooper(interval: .milliseconds(16)) {
//                directoryParent.position.y += cos(counter) * 2
//                directoryParent.scale = LFloat3(repeating: cos(counter / 10) + 2.float)
//                directoryParent.rotation.y = counter / 10
//                counter += 0.1
//            }.runUntil { false }
//        }
    }
}

private extension RenderPlan {
    func cacheGrids() {
        statusObject.update {
            $0.totalValue += 1 // pretend there's at least one unfinished task
            $0.message = "Starting grid cache..."
        }
        
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
                .filter { !$0.isDirectory }
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
            
            WorkerPool.shared.nextWorker().async {
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
