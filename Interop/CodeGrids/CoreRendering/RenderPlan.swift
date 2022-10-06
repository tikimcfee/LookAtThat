//
//  RenderPlan.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 5/21/22.
//

import SwiftSyntax
import Foundation

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
}

private extension RenderPlan {
    func doGridLayout() {
//        layoutBox()
//        layoutForce()
        layoutLazyBox()
    }
    
    private func layoutLazyBox() {
        var results = [URL: [URL]]()
        FileBrowser.recursivePaths(rootPath)
            .forEach { url in
                if url.isFileURL {
                    results[url.deletingLastPathComponent(), default: []]
                        .append(url)
                }
            }
        
        var lastStack: CodeGrid?
        var lastStart: LFloat3 = .zero
        var lastDirectory: MetalLinkNode?
        
        var maxWidth: Float = .zero
        var maxHeight: Float = .zero
        
        let xGap = 16.float
        let yGap = -64.float
        let zGap = -128.float
        
        let sorted = results.sorted(by: { leftPair, rightPair in
            let leftDistance = FileBrowser.distanceTo(parent: .directory(rootPath), from: .directory(leftPair.key))
            let rightDistance = FileBrowser.distanceTo(parent: .directory(rootPath), from: .directory(rightPair.key))
            if leftDistance < rightDistance { return true }
            if leftDistance > rightDistance { return false }
            return leftPair.key.path < rightPair.key.path
        })
        
        for (dir, files) in sorted {
            if files.isEmpty { continue }
            
            let sortedGrids = files
                .compactMap { builder.gridCache.get($0) }
                .sorted(by: { $0.lengthY < $1.lengthY })
                
            let directoryParent = MetalLinkNode()
            targetParent.add(child: directoryParent)
            targetParent.bindAsVirtualParentOf(directoryParent)
            
            for grid in sortedGrids {
                directoryParent.add(child: grid.rootNode)
                
                if let last = lastStack {
                    grid.setFront(last.back + zGap)
                }
                lastStack = grid
            }
            
            if let lastDirectory = lastDirectory {
                directoryParent
                    .setLeading(lastDirectory.trailing + xGap)
                    .setTop(lastDirectory.top)
                    .setFront(lastDirectory.front)
            }
            lastDirectory = directoryParent
            
            lastStack = nil
//            maxWidth = .zero
//            maxHeight = .zero
            
            // Test that each directory is properly parented with this cockamamie scheme
            var counter = 0.float + Float.random(in: 0..<(Float.pi * 2))
            QuickLooper(interval: .milliseconds(16)) {
                directoryParent.position.y += cos(counter) * 10
                counter += 0.1
            }.runUntil { false }
        }
    }
    
    private func layoutForce() {
//        let rootMap = ConcurrentDictionary<URL, [CodeGrid]>()
//        func appendTo(parent: URL, _ grid: CodeGrid) {
//            rootMap.directWriteAccess { writable  in
//                let array = writable[parent, default: [CodeGrid]()]
//                if let last = array.last {
//                    editor.snapping.connectWithInverses(sourceGrid: last, to: .backward(grid))
//                }
//                writable[parent, default: array].append(grid)
//            }
//        }
//        appendTo(parent: childPath.deletingLastPathComponent(), grid)
        
        let forceLayout = LForceLayout(
            snapping: editor.snapping
        )
        
        func getUnitVector(_ u: CodeGrid, _ v: CodeGrid) -> LFloat3 {
            let delta = v.position - u.position
            let magnitude = delta.magnitude
            return delta / magnitude
        }
        
        func getIdealLength(_ u: CodeGrid, _ v: CodeGrid) -> Float {
//            if let uPath = u.sourcePath, let vPath = v.sourcePath {
//                let pathDistance = FileBrowser.distanceTo(parent: .file(uPath), from: .file(vPath)).float
//                return pathDistance
//            }
//            return 1
            return 2
        }
        
        func clamp(_ minValue: LFloat3, _ value: LFloat3, _ maxValue: LFloat3) -> LFloat3 {
            return max(minValue, min(value, maxValue))
        }
        
        let MIN = LFloat3(repeating: -32)
        let MAX = LFloat3(repeating: 32)
        func clampForce(_ force: LFloat3) -> LFloat3 {
            return clamp(MIN, force, MAX)
        }
        
        let grids: [CodeGrid] = FileBrowser.recursivePaths(rootPath)
            .filter { !$0.isDirectory }
            .compactMap {
                guard let grid = self.builder.gridCache.get($0) else { return nil }
                targetParent.add(child: grid.rootNode)
                grid.position = LFloat3.random(in: 0.0..<1.0)
                return grid
            }
        
        forceLayout.doLayout(
            allVertices: grids,
            repulsiveFunction: { u, v in
                // repulse v -> u
                let delta = v.position - u.position
                let deltaMagnitude = delta.magnitude
                
                let ideal = getIdealLength(u, v)
                let idealSquared = ideal * ideal
                
                let unitVector = getUnitVector(u, v)
                let force = (idealSquared / deltaMagnitude) * unitVector
                return clampForce(force)
            },
            attractiveFunction: { u, v in
                // attract u -> v
                let delta = u.position - v.position
                let deltaMagnitude = delta.magnitude
                let squareMagnitude = deltaMagnitude * deltaMagnitude
                
                let unitVector = getUnitVector(v, u)
                let ideal = getIdealLength(u, v)
                
                let force = (squareMagnitude / ideal) * unitVector
                return clampForce(force)
            },
            maxIterations: 1_000,
            forceThreshold: LFloat3(0.1, 0.1, 0.1),
            coolingFactor: 0.997
        )
        
        for grid in grids {
            print("Final: ", grid.fileName, grid.position)
        }
    }
    
    private func layoutBox() {
        statusObject.update {
            $0.totalValue += 1
            $0.detail = "Layout: \(self.rootPath.lastPathComponent)"
        }
        
        var files = 0
        func doAdd(_ grid: CodeGrid) {
            targetParent.add(child: grid.rootNode)
            
            let nextRow: WorldGridEditor.AddStyle = .inNextRow(grid)
            let nextPlane: WorldGridEditor.AddStyle = .inNextPlane(grid)
            let trailing: WorldGridEditor.AddStyle = .trailingFromLastGrid(grid)
            
            if files > 0 && files % (50) == 0 {
                editor.transformedByAdding(nextPlane)
            } else if files > 0 && files % 10 == 0 {
                editor.transformedByAdding(nextRow)
            } else {
                editor.transformedByAdding(trailing)
            }
            
            files += 1
        }
        
        FileBrowser.recursivePaths(rootPath)
            .filter { !$0.isDirectory }
            .forEach { childPath in
            if let grid = self.builder.gridCache.get(childPath) {
                doAdd(grid)
            }
        }
        
        statusObject.update {
            $0.currentValue += 1
            $0.detail = "Layout complete: \(self.rootPath.lastPathComponent)"
        }
    }
}

private extension RenderPlan {
    func cacheGrids() {
        statusObject.update {
            $0.totalValue += 1 // pretend there's at least one unfinished task
            $0.message = "Starting grid cache..."
        }
        
        let dispatchGroup = DispatchGroup()
        FileBrowser.recursivePaths(rootPath)
            .filter { !$0.isDirectory }
            .forEach { childPath in
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
                    
                    builder.gridCache.cachedFiles[childPath] = grid.id
                    
                    statusObject.update {
                        $0.currentValue += 1
                        $0.detail = "File Complete: \(childPath.lastPathComponent)"
                    }
                   
                    hoverController.attachPickingStream(to: grid)
                    
                    dispatchGroup.leave()
                }
            }
        
        dispatchGroup.wait()
//        print("-- Cache complete")
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
