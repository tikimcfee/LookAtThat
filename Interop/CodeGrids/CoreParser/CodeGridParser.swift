//
//  CodeGridParser.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 10/22/21.
//

import Foundation
import SwiftSyntax
import SceneKit
import SwiftUI

class CodeGridParser: SwiftSyntaxFileLoadable {
    
    var cameraNode: SCNNode?
    var rootGeometryNode: SCNNode?
    
    let renderQueue = DispatchQueue(label: "RenderClock", qos: .userInitiated)
    
    let rootGridColor  = NSUIColor(displayP3Red: 0.0, green: 0.4, blue: 0.6, alpha: 0.2)
    let directoryColor = NSUIColor(displayP3Red: 0.2, green: 0.6, blue: 0.8, alpha: 0.2)
    
    var glyphCache: GlyphLayerCache = GlyphLayerCache()
    var tokenCache: CodeGridTokenCache = CodeGridTokenCache()
    
    lazy var editorWrapper: CodeGridWorld = {
        let world = CodeGridWorld(
            cameraProvider: { self.cameraNode },
            rootProvider: { self.rootGeometryNode }
        )
        return world
    }()
    
    lazy var gridCache: GridCache = {
        return GridCache(
            parser: self
        )
    }()
    
    lazy var concurrency: ConcurrentGridRenderer = {
        let cache = ConcurrentGridRenderer(
            parser: self,
            cache: gridCache
        )
        return cache
    }()
    
    lazy var query: CodeGridParserQueryController = {
        return CodeGridParserQueryController(
            parser: self
        )
    }()
}

// MARK: - Rendering strategies
class RecurseState {
    let snapping = WorldGridSnapping()
}

class CodeGridWorld {
    typealias Receiver = (_ camera: SCNNode, _ root: SCNNode) -> Void
    
    var cameraProvider: (() -> SCNNode?)?
    var rootProvider: (() -> SCNNode?)?
    
    init(
        cameraProvider: (() -> SCNNode?)?,
        rootProvider: (() -> SCNNode?)?
    ) {
        self.cameraProvider = cameraProvider
        self.rootProvider = rootProvider
    }
    
    func doInWorld(_ operation: Receiver) {
        guard let cam = cameraProvider?(),
              let root = rootProvider?()
        else { return }
        operation(cam, root)
    }
    
    func addInFrontOfCamera(grid: CodeGrid) {
        #if os(iOS)
        guard let cam = cameraProvider?(),
              let root = rootProvider?()
        else { return }
        
        let gridNode = grid.rootNode
        gridNode.position = cam.position * DeviceScaleRootInverse
        gridNode.simdPosition += cam.simdWorldFront * 300
        gridNode.simdOrientation = cam.simdOrientation
        root.addChildNode(gridNode)
        
        #endif
    }
    
    func addGrid(style: WorldGridEditor.AddStyle) {
        print("not implemented!", #function)
    }
    
    func changeFocus(_ direction: SelfRelativeDirection) {
        print("not implemented!", #function)
    }
}

class WorldGridNavigator {
    var directions: [String: Set<SelfRelativeDirection>] = [:]
    
    func isMovementAllowed(_ grid: CodeGrid, _ direction: SelfRelativeDirection) -> Bool {
        directionsForGrid(grid).contains(direction)
    }
    
    func directionsForGrid(_ grid: CodeGrid) -> Set<SelfRelativeDirection> {
        directions[grid.id] ?? []
    }
    
    func allowMovement(from grid: CodeGrid, to direction: SelfRelativeDirection) {
        var toAllow = directions[grid.id] ?? []
        toAllow.insert(direction)
        directions[grid.id] = toAllow
    }
}
