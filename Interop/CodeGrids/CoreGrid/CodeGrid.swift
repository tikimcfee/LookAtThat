//
//  CodeGrid.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 10/22/21.
//

import Foundation
import SceneKit
import SwiftSyntax

let kCodeGridContainerName = "CodeGrid"
let kWhitespaceNodeName = "XxX420blazeitspaceXxX"

extension CodeGrid {
    #if os(iOS)
    struct Defaults {
        
    }
    #else
    struct Defaults {
        
    }
    #endif
}

extension CodeGrid: CustomStringConvertible {
    public var description: String {
"""
CodeGrid(\(id))
""".trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

class GridMeta {
    var searchFocused = false
}

public class CodeGrid: Identifiable, Equatable {
    
    public lazy var id = { "\(kCodeGridContainerName)-\(UUID().uuidString)" }()
    
    var fileName: String = ""
    var sourcePath: URL?
    
    
    var consumedRootSyntaxNodes: [Syntax] = []
    var semanticInfoMap: SemanticInfoMap = SemanticInfoMap()
    let semanticInfoBuilder: SemanticInfoBuilder = SemanticInfoBuilder()
    
    private(set) var rootNode: GlyphCollection
    let tokenCache: CodeGridTokenCache
    let gridBackground: BackgroundQuad
    var updateVirtualParentConstants: ParentUpdater?
    
    var targetNode: MetalLinkNode { rootNode }
    var backgroundID: InstanceIDType { gridBackground.constants.pickingId }
    
    init(rootNode: GlyphCollection,
         tokenCache: CodeGridTokenCache) {
        self.rootNode = rootNode
        self.tokenCache = tokenCache
        self.gridBackground = BackgroundQuad(rootNode.link) // TODO: Link dependency feels lame
        
        setupOnInit()
    }
    
    func updateBackground() {
        let size = targetNode.contentSize
        gridBackground.scale.x = size.x / 2
        gridBackground.scale.y = size.y / 2
        
        gridBackground
            .setLeading(localLeading)
            .setTop(localTop)
            .setFront(localBack)
    }
    
    private func setupOnInit() {
        rootNode.modelEvents.sink { updatedBufferMatrix in
            self.updateVirtualParentConstants? {
                $0.modelMatrix = updatedBufferMatrix
            }
        }.store(in: &rootNode.eventBag)
        
        rootNode.add(child: gridBackground)
        gridBackground.constants.pickingId = InstanceCounter.shared.nextGridId()
    }
    
    public static func == (_ left: CodeGrid, _ right: CodeGrid) -> Bool {
        laztrace(#fileID,#function,left,right)
        return left.id == right.id
    }
}

// MARK: - Hashing
extension CodeGrid: Hashable {
    public func hash(into hasher: inout Hasher) {
        laztrace(#fileID,#function,hasher)
        hasher.combine(id)
    }
}

// MARK: - Builder-style configuration
// NOTE: - Word of warning
// Grids can describe an entire glyph collection, or represent
// a set of nodes in a collection. Because of this dual job and
// from how the clearinghouse went, Grids owned a reference
// to a collection now, and assume they are the representing object.
// TODO: Add another `GroupMode` to switch between rootNode and collection node updates
extension CodeGrid: Measures {
    var bounds: Bounds {
        targetNode.bounds
    }
    
    var boundsCacheKey: BoundsKey {
        targetNode
    }
    
    var rectPos: Bounds {
        targetNode.rectPos
    }

    var hasIntrinsicSize: Bool {
        targetNode.hasIntrinsicSize
    }
    
    var contentSize: LFloat3 {
        targetNode.contentSize
    }
    
    var contentOffset: LFloat3 {
        targetNode.contentOffset
    }
    
    var nodeId: String {
        targetNode.nodeId
    }
    
    var position: LFloat3 {
        get {
            targetNode.position
        }
        set {
            targetNode.position = newValue
        }
    }
    
    var worldPosition: LFloat3 {
        get {
            targetNode.worldPosition
        }
        set {
            targetNode.worldPosition = newValue
        }
    }
    
    var rotation: LFloat3 {
        get {
            targetNode.rotation
        }
        set {
            targetNode.rotation = newValue
        }
    }
    
    var lengthX: Float {
        targetNode.lengthX
    }
    
    var lengthY: Float {
        targetNode.lengthY
    }
    
    var lengthZ: Float {
        targetNode.lengthZ
    }
    
    var parent: MetalLinkNode? {
        get {
            targetNode.parent
        }
        set {
            targetNode.parent = newValue
        }
    }
    
    func convertPosition(_ position: LFloat3, to: MetalLinkNode?) -> LFloat3 {
        targetNode.convertPosition(position, to: to)
    }
    
    func enumerateChildren(_ action: (MetalLinkNode) -> Void) {
        targetNode.enumerateChildren(action)
    }
    
    var centerPosition: LFloat3 {
        return LFloat3(x: targetNode.centerX, y: targetNode.centerY, z: targetNode.centerZ)
    }
}

extension CodeGrid {
    
    @discardableResult
    func zeroedPosition() -> CodeGrid {
        position = .zero
        return self
    }
    
    @discardableResult
    func translated(
        dX: Float = 0,
        dY: Float = 0,
        dZ: Float = 0
    ) -> CodeGrid {
        laztrace(#fileID,#function,dX,dY,dZ)
        position = position.translated(dX: dX, dY: dY, dZ: dZ)
        return self
    }
    
    @discardableResult
    func applying(_ action: (Self) -> Void) -> Self {
        laztrace(#fileID,#function)
        action(self)
        return self
    }
    
    @discardableResult
    func withFileName(_ fileName: String) -> Self {
        self.fileName = fileName
        return self
    }
    
    @discardableResult
    func withSourcePath(_ filePath: URL) -> Self {
        self.sourcePath = filePath
        return self
    }
}
