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

private extension RenderPlan {
    func doGridLayout() {
//        layoutBox()
        layoutForce()
    }
    
    private func layoutForce() {
        let idealLength: Float = 100.0
        let idealSquared: Float = idealLength * idealLength
        let forceLayout = LForceLayout()
        
        func getUnitVectorPair(_ u: CodeGrid, _ v: CodeGrid) -> (LFloat3, Float) {
            let delta = v.position - u.position
            let distance = distance(v.position, u.position)
            let unitVector = delta / distance
            return (unitVector, distance)
        }
        
        let grids: [CodeGrid] = FileBrowser.recursivePaths(rootPath)
            .filter { !$0.isDirectory }
            .compactMap {
                guard let grid = self.builder.gridCache.get($0) else { return nil }
                targetParent.add(child: grid.rootNode)
                grid.position = LFloat3.random(in: 0.0..<100.0)
                return grid
            }
        
        forceLayout.doLayout(
            allVertices: grids,
            repulsiveFunction: { repulseLeft, repulseRight in
                // repul v -> u
                let (unitVector, distance) = getUnitVectorPair(repulseLeft, repulseRight)
                return (idealSquared / distance) * unitVector
            },
            attractiveFunction: { attractLeft, attractRight in
                // attract u -> v
                let (unitVector, distance) = getUnitVectorPair(attractRight, attractLeft)
                return ((distance * distance) / idealLength) * unitVector
            },
            edgeLength: idealLength,
            maxIterations: 100,
            forceThreshold: LFloat3(10, 10, 10),
            coolingFactor: 0.88
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
