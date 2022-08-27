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
    
    let renderQueue = DispatchQueue(label: "RenderClock", qos: .userInitiated)
    
    var glyphCache: GlyphLayerCache = GlyphLayerCache()
    var tokenCache: CodeGridTokenCache = CodeGridTokenCache()
    
    lazy var editorWrapper: CodeGridWorld = {
        let world = CodeGridWorld()
        return world
    }()
    
    lazy var gridCache: GridCache = {
        return GridCache(
            tokenCache: tokenCache
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
    
    init() {
        
    }
    
    func doInWorld(_ operation: Receiver) {
        
    }
    
    func addInFrontOfCamera(grid: CodeGrid) {
        
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
