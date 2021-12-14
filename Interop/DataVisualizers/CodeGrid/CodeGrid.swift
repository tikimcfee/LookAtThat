//
//  CodeGrid.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 10/22/21.
//

import Foundation
import SceneKit
import SwiftSyntax

let kCodeGridContainerName = "kCodeGridContainerName"
let kWhitespaceNodeName = "XxX420blazeitspaceXxX"

class CodeGridControl {
    let targetGrid: CodeGrid
    let displayGrid: CodeGrid
    
    init(targetGrid: CodeGrid, displayGrid: CodeGrid) {
        self.targetGrid = targetGrid
        self.displayGrid = displayGrid
    }
    
    func test() {

    }
}

class CodeGrid: Identifiable, Equatable {
    struct Defaults {
        static var displayMode: DisplayMode = .all
        static var walkSemantics: Bool = true
    }
    
    lazy var id = { "\(kCodeGridContainerName)-\(UUID().uuidString)" }()
    lazy var glyphNodeName = { "\(id)-glyphs" }()
    lazy var backgroundNodeName = { "\(id)-background" }()
    var cloneId: ID { "\(id)-clone" }
    
    let tokenCache: CodeGridTokenCache
    let glyphCache: GlyphLayerCache
    
    lazy var fullTextBlitter = CodeGridBlitter(id)
    let fullTextLayerBuilder: FullTextLayerBuilder = FullTextLayerBuilder()
    
    var codeGridSemanticInfo: CodeGridSemanticMap = CodeGridSemanticMap()
    let semanticInfoBuilder: SemanticInfoBuilder = SemanticInfoBuilder()
    
    var walkSemantics: Bool = Defaults.walkSemantics
    var displayMode: DisplayMode = Defaults.displayMode {
        didSet { didSetDisplayMode() }
    }
    
    let pointer = Pointer()
    lazy var renderer: CodeGrid.Renderer = CodeGrid.Renderer(targetGrid: self)
    lazy var measures: CodeGrid.Measures = CodeGrid.Measures(targetGrid: self)
    
    lazy var rootNode: SCNNode = makeRootNode()
    lazy var rootGlyphsNode: SCNNode = makeRootGlyphsNode()
    lazy var backgroundGeometryNode: SCNNode = makeBackgroundGeometryNode()
    lazy var backgroundGeometry: SCNBox = makeBackgroundGeometry()
    
    init(_ id: String? = nil,
         glyphCache: GlyphLayerCache,
         tokenCache: CodeGridTokenCache) {
        self.glyphCache = glyphCache
        self.tokenCache = tokenCache
        self.id = id ?? self.id
    }
    
    public static func == (_ left: CodeGrid, _ right: CodeGrid) -> Bool {
        laztrace(#fileID,#function,left,right)
        return left.id == right.id
    }
}

// MARK: -- Builders for lazy properties
extension CodeGrid {
    private func makeRootNode() -> SCNNode {
        laztrace(#fileID,#function)
        let container = SCNNode()
        container.name = id
        container.addChildNode(rootGlyphsNode)
        container.addChildNode(backgroundGeometryNode)
        return container
    }
    
    private func makeRootGlyphsNode() -> SCNNode {
        laztrace(#fileID,#function)
        let container = SCNNode()
        container.name = glyphNodeName
        container.categoryBitMask = HitTestType.codeGridGlyphs.rawValue
        return container
    }
    
    private func makeBackgroundGeometryNode() -> SCNNode {
        laztrace(#fileID,#function)
        let backgroundNode = SCNNode()
        backgroundNode.name = backgroundNodeName
        backgroundNode.geometry = backgroundGeometry
        backgroundNode.categoryBitMask = HitTestType.codeGrid.rawValue
        return backgroundNode
    }
    
    private func makeBackgroundGeometry() -> SCNBox {
        laztrace(#fileID,#function)
        let sheetGeometry = SCNBox()
        sheetGeometry.chamferRadius = 4.0
        sheetGeometry.firstMaterial?.diffuse.contents = NSUIColor.black
        sheetGeometry.length = PAGE_EXTRUSION_DEPTH
        return sheetGeometry
    }
}

// MARK: -- Hashing
extension CodeGrid: Hashable {
    func hash(into hasher: inout Hasher) {
        laztrace(#fileID,#function,hasher)
        hasher.combine(id)
    }
}

// MARK: -- Displays configuration
extension CodeGrid {
    enum DisplayMode {
        case glyphs
        case layers
        case all
    }
    
    private func didSetDisplayMode() {
        recomputeDisplayMode()
    }
    
    func recomputeDisplayMode() {
        switch displayMode {
        case .layers:
            fullTextBlitter.rootNode.isHidden = false
            rootGlyphsNode.isHidden = true
        case .glyphs:
            fullTextBlitter.rootNode.isHidden = true
            rootGlyphsNode.isHidden = false
        case .all:
            fullTextBlitter.rootNode.isHidden = false
            rootGlyphsNode.isHidden = true
        }
    }
    
    @discardableResult
    func sizeGridToContainerNode(
        pad: VectorFloat = 2.0,
        pivotRootNode: Bool = false
    ) -> CodeGrid {
        laztrace(#fileID,#function,pad,pivotRootNode)
        backgroundGeometry.width = rootNode.lengthX.cg + pad.cg
        backgroundGeometry.height = rootNode.lengthY.cg + pad.cg
        let centerX = backgroundGeometry.width / 2.0
        let centerY = -backgroundGeometry.height / 2.0
        backgroundGeometryNode.position.x = centerX.vector - pad / 2.0
        backgroundGeometryNode.position.y = centerY.vector + pad / 2.0
        backgroundGeometryNode.position.z = -1
        // Can help in some layout situations where you want the root node's position
        // to be at dead-center of background geometry

        //        if pivotRootNode {
//            rootNode.pivot = SCNMatrix4MakeTranslation(centerX.vector, centerY.vector, 0)
//        }
        
//        rootNode.pivot = SCNMatrix4MakeTranslation(pad, -pad, 0)
        
        // Manual bounding box needs to me manually updated after initial layout
        // too account for new geometry position
        _ = SCNNode.BoundsCaching.Update(rootNode, false)
        
        return self
    }
    
    @discardableResult
    func zeroedPosition() -> CodeGrid {
        rootNode.position = SCNVector3(x: 0, y: 0, z: 0)
        return self
    }
    
    @discardableResult
    func translated(dX: VectorFloat = 0,
                    dY: VectorFloat = 0,
                    dZ: VectorFloat = 0) -> CodeGrid {
        laztrace(#fileID,#function,dX,dY,dZ)
        rootNode.position = rootNode.position.translated(dX: dX, dY: dY, dZ: dZ)
        return self
    }
    
    @discardableResult
    func backgroundColor(_ color: NSUIColor) -> CodeGrid {
        laztrace(#fileID,#function,color)
        backgroundGeometry.firstMaterial?.diffuse.contents = color
        fullTextBlitter.gridGeometry.firstMaterial?.diffuse.contents = color
        return self
    }
    
    @discardableResult
    func applying(_ action: (Self) -> Void) -> Self {
        laztrace(#fileID,#function)
        action(self)
        return self
    }
}
