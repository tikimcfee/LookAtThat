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
//        layoutWide()
//        layoutLazyBox()
        layoutFullGood()
    }
    
    private func layoutFullGood() {
        var positionZ: Float = 0.0
        for (url, thisDirectoryParent) in state.orderedParents {
//            print("url: ", url, "\ndir: ", directoryParent)
            
            
            func attachDirectories() {
                var directoryParentsParentURL = url.deletingLastPathComponent()
                var directoryParentsParentGrid: CodeGrid?
                while directoryParentsParentURL.pathComponents.count > 1, directoryParentsParentGrid == nil {
                    directoryParentsParentGrid = state.orderedParents[directoryParentsParentURL]
                    directoryParentsParentURL.deleteLastPathComponent()
                }
                
                if let directoryParentsParentGrid {
                    let position = getDirectoryBasedPosition(of: url)
                    
                    directoryParentsParentGrid.childGrids.last?.bounds.max.x + 32
                    directoryParentsParentGrid.addChildGrid(thisDirectoryParent.translated(deltaPosition: position))
                } else {
                    targetParent.add(
                        child: thisDirectoryParent.rootNode.translated(
                            dY: 0.0,
                            dZ: positionZ
                        )
                    )
                }
            }
            attachDirectories()
            
            var childPositionX: Float = 0.0
            for url in url.children(recursive: false) {
                if url.isDirectory {
//                    let parentOfDirectory = url.parent
                } else {
                    if let grid = self.builder.sharedGridCache.get(url) {
                        thisDirectoryParent.addChildGrid(
                            grid.translated(
                                dX: childPositionX,
                                dY: getDirectoryBasedPosition(of: url).y
                            )
                        )
                        childPositionX += grid.boundsWidth + 32
                    }
                }
                
            }
            
            positionZ += 100
        }
        addParentWalls()
    }
    
//    private func layoutWide() {
//        let calculator = DirectoryCalculator()
//        let _ = calculator.computeTotalSizeOfDirectory(at: rootPath)
//        calculator.traverseTreeSecondPass_Y(root: rootPath)
//
//        for (url, position) in calculator.positionDict {
//            if let grid = self.builder.sharedGridCache.get(url) {
//                grid.position = LFloat3(position.0, position.1, position.2)
//                targetParent.add(child: grid.rootNode)
//            }
//        }
//        addParentWalls()
//    }
    
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
    
//    private func layoutLazyBox() {
//        // MARK: - Do final layout
//        let xGap = 16.float
//        var lastDirectory: CodeGrid?
//        let layout = DepthLayout()
//
//        for (url, directoryParent) in state.orderedParents {
//            let sortedLayoutChildren = directoryParent.rootNode.children.sorted(
//                by: { $0.lengthY < $1.lengthY }
//            )
//            layout.layoutGrids(sortedLayoutChildren)
//
//            let directoryPlanePosition = getDirectoryBasedPosition(of: url)
//            directoryParent.translated(dY: directoryPlanePosition.y)
//
//            if let lastDirectory = lastDirectory {
//                directoryParent
//                    .setFront(directoryPlanePosition.z)
//                    .setLeading(lastDirectory.trailing + xGap)
//                    .setTop(lastDirectory.bottom + 32)
//            }
//
//            lastDirectory = directoryParent
//        }
//
//        addParentWalls()
//    }
    
    func addParentWalls() {
        for (url, thisParent) in state.orderedParents {
            let gridBackground = BackgroundQuad(GlobalInstances.defaultLink)
            let gridTopWall = BackgroundQuad(GlobalInstances.defaultLink)
            let gridRightWall = BackgroundQuad(GlobalInstances.defaultLink)
            gridBackground.setColor(LFloat4(0.4, 0.2, 0.2, 0.5))
            gridTopWall.setColor(LFloat4(0.3, 0.2, 0.2, 0.5))
            gridRightWall.setColor(LFloat4(0.2, 0.1, 0.1, 0.5))
            
            let computing = BoundsComputing()
            for child in FileBrowser.recursivePaths(url) {
                guard !child.isDirectory else { continue }
                if let grid = builder.sharedGridCache.get(child) {
                    computing.consumeBounds(grid.bounds)
                }
            }
//            thisParent.childGrids.forEach {
//                computing.consumeBounds($0.bounds)
//            }
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
            
            thisParent.rootNode.add(child: gridBackground)
            thisParent.rootNode.add(child: gridTopWall)
            thisParent.rootNode.add(child: gridRightWall)
            
            var lineParent = url.deletingLastPathComponent()
            var thisParentParent: CodeGrid?
            while lineParent.pathComponents.count > 1, thisParentParent == nil {
                thisParentParent = state.orderedParents[lineParent]
                lineParent.deleteLastPathComponent()
            }
            
//            if let thisParentParent {
//                let line = MetalLinkLine(GlobalInstances.defaultLink)
//                line.setColor(LFloat4(1.0, 0.8, 0.1, 1.0))
//                line.appendSegment(
//                    about: thisParentParent.position
//                )
//                line.appendSegment(
//                    about: LFloat3(
//                        x: thisParent.position.x,
//                        y: thisParentParent.position.y,
//                        z: thisParentParent.position.z
//                    )
//                )
//                line.appendSegment(
//                    about: LFloat3(
//                        x: thisParent.position.x - 10.0,
//                        y: thisParent.position.y + 10.0,
//                        z: thisParentParent.position.z - 10.0
//                    )
//                )
//                line.appendSegment(
//                    about: thisParent.position
//                )
////                targetParent.add(child: line)
//                thisParent.rootNode.add(child: line)
////                thisParentParent
////                thisParentParent
//            }
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
                } else if childPath.isDirectory {
                    let childDirectoryGrid = builder.sharedGridCache.setCache(childPath)
                    state.orderedParents[childPath] = childDirectoryGrid
//                    targetParent.add(child: childDirectoryGrid.rootNode)
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
