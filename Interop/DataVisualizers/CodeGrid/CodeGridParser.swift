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
    
    let renderQueue = DispatchQueue(label: "RenderClock", qos: .userInitiated)
    
    let rootGridColor  = NSUIColor(displayP3Red: 0.0, green: 0.4, blue: 0.6, alpha: 0.2)
    let directoryColor = NSUIColor(displayP3Red: 0.2, green: 0.6, blue: 0.8, alpha: 0.2)
    
    lazy var glyphCache: GlyphLayerCache = {
        GlyphLayerCache()
    }()
    
    lazy var tokenCache: CodeGridTokenCache = {
        CodeGridTokenCache()
    }()
    
    lazy var editorWrapper: CodeGridWorld = {
        let world = CodeGridWorld(cameraProvider: {
            self.cameraNode
        })
        return world
    }()
    
    lazy var gridCache: GridCache = {
        return GridCache(
            parser: self
        )
    }()
    
    lazy var concurrency: TotalProtonicConcurrency = {
        let cache = TotalProtonicConcurrency(
            parser: self,
            cache: gridCache
        )
        return cache
    }()
    
    lazy var query: ParserQueryController = {
        return ParserQueryController(
            parser: self
        )
    }()
}

// MARK: - Rendering strategies
class RecurseState {
    let snapping = WorldGridSnapping()
}

class CodeGridWorld {
    var rootContainerNode: SCNNode = SCNNode()
    var worldGridEditor = WorldGridEditor()
    var cameraProvider: (() -> SCNNode?)?
    
    init(cameraProvider: (() -> SCNNode?)?) {
        self.cameraProvider = cameraProvider
    }
    
    func addInFrontOfCamera(style: WorldGridEditor.AddStyle) {
        #if os(iOS)
        guard let cam = cameraProvider?() else { return }
        
        let gridNode = style.grid.rootNode
        
        gridNode.simdPosition = cam.simdPosition
        gridNode.simdPosition += cam.simdWorldFront * 0.5
        
        gridNode.simdEulerAngles.y = cam.simdEulerAngles.y
        gridNode.simdEulerAngles.x = cam.simdEulerAngles.x
//        gridNode.simdEulerAngles.z = cam.simdEulerAngles.z
        gridNode.scale = SCNVector3(x: 0.01, y: 0.01, z: 0.01)
        
        gridNode.simdPosition += -cam.simdWorldRight * (0.5 * gridNode.lengthX * 0.01)
        rootContainerNode.addChildNode(gridNode)
        #endif
    }
    
    func addGrid(style: WorldGridEditor.AddStyle) {
        worldGridEditor.transformedByAdding(style)
    }
    
    func changeFocus(_ direction: SelfRelativeDirection) {
        worldGridEditor.shiftFocus(direction)
        moveCameraToFocus()
    }
    
    private func moveCameraToFocus() {
        guard let camera = cameraProvider?(),
              let grid = worldGridEditor.lastFocusedGrid
        else {
            print("updated focus to empty grid")
            return
        }
        camera.position = grid.rootNode.position.translated(
            dX: grid.measures.lengthX / 2.0,
            dY: -min(32, grid.measures.lengthY / 4.0),
            dZ: default__CameraSpacingFromPlaneOnShift
        )
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

class ParserQueryController: ObservableObject {
    let parser: CodeGridParser
    var tokenCache: CodeGridTokenCache { parser.tokenCache }
    var cache: GridCache { parser.gridCache }
    
    @Published var searchInput: String = ""
    lazy var searchBinding = WrappedBinding("", onSet: { self.searchInput = $0 })
    lazy var searchStream = $searchInput.share().eraseToAnyPublisher()
    
    init(parser: CodeGridParser) {
        self.parser = parser
    }
    
    func walkGridsForSearch(
        _ searchText: String,
        onPositive: (CodeGrid, SemanticInfo) -> Void,
        onNegative: (CodeGrid, SemanticInfo) -> Void
    ) {
        onAllCachedInfo { grid, info in
            let isIncluded = info.referenceName.fuzzyMatch(searchText)
            let toCall = isIncluded ? onPositive : onNegative
            toCall(grid, info)
        }
    }
    
    func walkNodesForSearch(
        _ searchText: String,
        onPositive: (CodeGrid, SemanticInfo, GridAssociationType) -> Void,
        onNegative: (CodeGrid, SemanticInfo, GridAssociationType) -> Void
    ) {
        onAllCachedInfo { grid, info in
            let isIncluded = info.referenceName.contains(searchText)
            let toCall = isIncluded ? onPositive : onNegative
            
            let infoTokenId = info.syntaxId
            grid.codeGridSemanticInfo
                .forAllNodesAssociatedWith(infoTokenId, tokenCache) { info, associations in
                    toCall(grid, info, associations)
                }
        }
    }
    
    // Loops through all grids, iterates over all SemanticInfo constructed for it
    func onAllCachedInfo(_ receiver: (CodeGrid, SemanticInfo) -> Void) {
        for cachedGrid in cache.cachedGrids.values {
            cachedGrid.codeGridSemanticInfo
                .semanticsLookupBySyntaxId
                .values.forEach { info in
                    receiver(cachedGrid, info)
                }
        }
    }
    
    func forAllGrids(_ receiver: (CodeGrid) -> Void) {
        for cachedGrid in cache.cachedGrids.values {
            receiver(cachedGrid)
        }
    }
}
