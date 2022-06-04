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
                } else {
                    let pathGrid = renderer.syncAccess(childPath)
                    doAppend(pathGrid)
                }
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
}

extension RenderPlan {
    class FileCylinder {
        let id: String = UUID().uuidString
        let rootNode: SCNNode = SCNNode()
        let rootUrl: URL
        let plan: RenderPlan
        
        init(url: URL,
             plan: RenderPlan) {
            self.rootUrl = url
            self.plan = plan
            
            rootNode.name = id
            addAll()
        }
        
        func addAll() {
            // given x (x=7) files, distribute radians evenly
            // 1 circle == 2pi => 2pi / x -> 2pi / 7
            // start 0, iterate to 2pi by (2pi/7) steps
            let expectedChildren = rootUrl.filterdChildren { !$0.isDirectory }
            let fileCount = expectedChildren.count
            let twoPi = 2.0 * VectorVal.pi
            let radiansPerFile = twoPi / VectorVal(fileCount)
            let radianStride = stride(from: 0.0, to: twoPi, by: radiansPerFile)
            zip(expectedChildren, radianStride).forEach { path, radians in
                let grid = plan.renderer.syncAccess(path)
                let magnitude = VectorVal(16.0)
                let dX = cos(radians) * magnitude
                let dY = -(sin(radians) * magnitude)
                
                // translate dY unit vector along z-axis, rotating the unit circle along x
                grid.rootNode.translate(dX: dX, dZ: dY)
                grid.rootNode.eulerAngles.y = radians
                rootNode.addChildNode(grid.rootNode)
            }
        }
    }
        
    func renderCylinder() {
        
        var directoryCylinders = [URL: FileCylinder]()
        let rootNode = SCNNode()
        iterateRoot { childPath in
            if childPath.isDirectory {
                let cylinder = FileCylinder(url: childPath, plan: self)
                rootNode.addChildNode(cylinder.rootNode)
            } else {
                let parent = childPath.deletingLastPathComponent()
                guard directoryCylinders[parent] == nil else { return }
                
                let cylinder = FileCylinder(url: parent, plan: self)
                rootNode.addChildNode(cylinder.rootNode)
                directoryCylinders[parent] = cylinder
            }
        }
        
        sceneState.rootGeometryNode.addChildNode(rootNode)
    }
}
