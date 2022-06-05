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
    let rootPath: URL
    let queue: DispatchQueue
    
    let renderer: ConcurrentGridRenderer
    let state: RecurseState = RecurseState()
    let compatShim = CodePagesController.shared.compat
    let sceneState = CodePagesController.shared.sceneState
    
    var focusCompat: CodeGridFocusController { compatShim.inputCompat.focus }
    var currentFocus: FocusBox { focusCompat.currentTargetFocus }
    
    func startRender() {
        queue.async {
            WatchWrap.startTimer("\(rootPath.fileName)")
            cacheGrids()
            renderFoci()
            WatchWrap.stopTimer("\(rootPath.fileName)")
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
    
    private func iterateRoot(
        _ recursive: Bool = true,
        _ receiver: (URL) -> Void
    ) {
        FileBrowser.recursivePaths(rootPath)
            .forEach { childPath in
                receiver(childPath)
            }
    }
}

extension RenderPlan {
    private func renderFoci() {
        var focusParents = [URL: FocusBox]()
        let rootFocus = focusCompat.currentTargetFocus
        focusParents[rootPath] = rootFocus
        
        FileBrowser.recursivePaths(rootPath)
            .forEach { childPath in
                let parentPath = childPath.deletingLastPathComponent()
                if childPath.isDirectory {
                    focusCompat.setNewFocus()
                    focusParents[childPath] = focusCompat.currentTargetFocus
                    
                    if let parent = focusParents[parentPath] {
                        focusCompat.doRender(on: parent) {
                            parent.addChildFocus(focusCompat.currentTargetFocus)
                        }
                    }
                    
                } else {
                    guard let parent = focusParents[parentPath] else {
                        print("Missing parent for \(parentPath)")
                        return
                    }
                    
                    let pathGrid = renderer.syncAccess(childPath)
                    focusCompat.doRender(on: parent) {
                        parent.attachGrid(pathGrid, parent.deepestDepth + 1)
                    }
                }
            }
    }
}
