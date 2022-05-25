//
//  RenderPlan.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 5/21/22.
//

import SwiftSyntax
import SceneKit
import SwiftUI

class WatchWrap {
    static let stopwatch = Stopwatch(running: false)
    
    static func startTimer(_ name: String) {
        print("* Starting \(name)")
        stopwatch.start()
    
    }
    static func stopTimer(_ name: String) {
        defer { stopwatch.reset() }
        stopwatch.stop()
        let time = Self.stopwatch.elapsedTimeString()
        print("* Time for \(name): \(time)")
    }
}

struct RenderPlan {
    let rootPath: FileKitPath
    let queue: DispatchQueue
    
    let renderer: ConcurrentGridRenderer
    let state: RecurseState = RecurseState()
    let compatShim = CodePagesController.shared.compat
    
    var focusCompat: CodeGridFocusController { compatShim.inputCompat.focus }
    var currentFocus: FocusBox { focusCompat.currentTargetFocus }
    
    func startRender() {
        queue.async {
            WatchWrap.startTimer("\(rootPath.fileName)")
            renderInternal()
            WatchWrap.stopTimer("\(rootPath.fileName)")
        }
    }
    
    private func renderInternal() {
        cacheGrids()
        
        var currentFocusNeedsFinish = false
        FileBrowser.recursivePaths(rootPath)
            .forEach { childPath in
                if childPath.isDirectory {
                    // Move dX from last node
                    var startPosition = SCNVector3()
                    if let lastFocusNode = state.snapping.nodeReg1 {
                        let nodeWidth = BoundsWidth(lastFocusNode.manualBoundingBox).vector
                        startPosition = lastFocusNode.position.translated(dX: nodeWidth)
                    }
                    state.snapping.nodeReg1 = currentFocus.rootNode
                    currentFocus.rootNode.position = startPosition
                    
                    compatShim.inputCompat.focus.setNewFocus()
                    currentFocusNeedsFinish = false
                } else {
                    currentFocusNeedsFinish = true
                    let pathGrid = renderer.syncAccess(childPath)
                    doAppend(pathGrid)
                }
            }
        
        if currentFocusNeedsFinish {
            currentFocusNeedsFinish = false
        }
    }

    private func doAppend(_ newGrid: CodeGrid) {
        focusCompat.resize { _, _ in
            sceneTransaction(0) {
                focusCompat.layout { focus, box in
                    focus.appendToTarget(grid: newGrid)
                }
            }
        }
    }
    
    private func cacheGrids() {
        let dispatchGroup = DispatchGroup()
        FileBrowser.recursivePaths(rootPath)
            .filter { !$0.isDirectory }
            .forEach { childPath in
                dispatchGroup.enter()
                renderer.asyncAccess(childPath) { _ in
                    dispatchGroup.leave()
                }
            }
        
        dispatchGroup.wait()
    }
}
