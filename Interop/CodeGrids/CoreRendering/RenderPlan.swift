//
//  RenderPlan.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 5/21/22.
//

import SwiftSyntax
import SceneKit
import SwiftUI
import SCNLine

struct RenderPlan {
    let rootPath: URL
    let queue: DispatchQueue
    
    let renderer: ConcurrentGridRenderer
    let state: RecurseState = RecurseState()
    let lines: LineVendor = LineVendor()
    let compatShim = CodePagesController.shared.compat
    let sceneState = CodePagesController.shared.sceneState
    
    var focusCompat: CodeGridFocusController { compatShim.inputCompat.focus }
    var currentFocus: FocusBox { focusCompat.currentTargetFocus }
    
    func startRender(_ onComplete: @escaping (FocusBox) -> Void) {
        queue.async {
            WatchWrap.startTimer("\(rootPath.fileName)")
            
            cacheGrids()
            let rootFocus = renderFoci()
            recursiveLinesLocal(rootFocus)
            
            WatchWrap.stopTimer("\(rootPath.fileName)")
            onComplete(rootFocus)
        }
    }
}

extension RenderPlan {
    class State {
        var focusParents = [URL: FocusBox]()
        let rootFocus: FocusBox
        let rootPath: URL
        init(rootFocus: FocusBox,
             rootPath: URL) {
            self.rootFocus = rootFocus
            self.rootPath = rootPath
            self.focusParents[rootPath] = rootFocus
        }
        subscript(_ path: URL) -> FocusBox? {
            get { focusParents[path] }
            set { focusParents[path] = newValue }
        }
    }
}

private extension RenderPlan {
    func renderFoci() -> FocusBox {
        let state = State(
            rootFocus: focusCompat.currentTargetFocus,
            rootPath: rootPath
        )

        FileBrowser.recursivePaths(rootPath)
            .forEach { childPath in
                doPathRender(childPath, state)
            }
        
        return state.rootFocus
    }
    
    func doPathRender(
        _ childPath: URL,
        _ state: State
    ) {
        let parentPath = childPath.deletingLastPathComponent()
        
        if childPath.isDirectory {
            focusCompat.setNewFocus()
            let newFocus = focusCompat.currentTargetFocus
            state[childPath] = newFocus
            
            if let parent = state[parentPath] {
                focusCompat.doRender(on: parent) {
                    parent.addChildFocus(newFocus)
                }
            } else {
                print("MISSING! \(parentPath.lastPathComponent)")
            }
            
        } else {
            guard let parent = state[parentPath] else {
                print("Missing parent for \(parentPath)")
                return
            }
            let pathGrid = renderer.syncAccess(childPath)
            focusCompat.doRender(on: parent) {
                parent.attachGrid(pathGrid, parent.deepestDepth + 1)
            }
        }
    }
    
    func recursiveLinesLocal(_ rootFocus: FocusBox) {
        rootFocus.childFocusBimap.keysToValues.keys.forEach { childFocus in
            let line = lines.newConnection(
                from: childFocus.rootNode.position,
                to: SCNVector3Zero,
                materialContents: lines.color(for: childFocus)
            )
            rootFocus.rootNode.addChildNode(line)
            recursiveLinesLocal(childFocus)
        }
    }
}

private extension RenderPlan {
    func cacheGrids() {
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
    
    func iterateRoot(
        _ recursive: Bool = true,
        _ receiver: (URL) -> Void
    ) {
        FileBrowser.recursivePaths(rootPath)
            .forEach { childPath in
                receiver(childPath)
            }
    }
}

class LineVendor {
    var colorCache = AutoCache<FocusBox, NSUIColor>()
    
    func color(for parent: FocusBox) -> Any {
        var computedRGB: NSUIColor {
            let depth = Double(parent.depthInFocusHierarchy + 1)
            let base = 0.33
            let scaled = (pow(base, depth))
            return NSUIColor(
                displayP3Red: scaled / 1.5,
                green: scaled / 1.5,
                blue: scaled,
                alpha: 1.0
            )
        }
        
        var switchedRBG: NSUIColor {
            let colors: (Double, Double, Double, Double)
            switch parent.depthInFocusHierarchy {
            case 0: colors = (0.0, 0.0, 0.6, 1.0)
            case 1: colors = (0.0, 0.6, 0.0, 1.0)
            case 2: colors = (0.6, 0.0, 0.0, 1.0)
            case 3: colors = (0.6, 0.0, 0.6, 1.0)
            case 4: colors = (0.6, 0.6, 0.0, 1.0)
            case 5: colors = (0.9, 0.9, 0.4, 1.0)
            case 6: colors = (0.3, 0.3, 0.8, 1.0)
            case 7: colors = (0.7, 0.7, 0.1, 1.0)
            default: colors = (1.0, 1.0, 1.0, 1.0)
            }
            return NSUIColor(
                displayP3Red: colors.0,
                green: colors.1,
                blue: colors.2,
                alpha: colors.3
            )
        }
        
        let color = colorCache.retrieve(key: parent, defaulting: switchedRBG)
        return color
    }
    
    func newConnection(
        from startPosition: SCNVector3,
        to endPosition: SCNVector3,
        materialContents: Any
    ) -> SCNLineNode {
        let line = SCNLineNode(
            with: [startPosition, endPosition],
            radius: 2.0,
            edges: 16,
            maxTurning: 8
        )
        if let material = line.geometry?.firstMaterial {
            material.diffuse.contents = materialContents
            material.isDoubleSided = true
        }
        return line
    }
}

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
