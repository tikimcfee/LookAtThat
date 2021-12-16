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

extension CodeGrid {
    struct Defaults {
        static var displayMode: DisplayMode = .all
        static var walkSemantics: Bool = true
    }
}

class CodeGridControl {
    let targetGrid: CodeGrid
    let displayGrid: CodeGrid
    
    typealias Receiver = (CodeGridControl) -> Void
    var didActivate: Receiver?
    
    init(targetGrid: CodeGrid) {
        self.targetGrid = targetGrid
        self.displayGrid = targetGrid.newGridUsingCaches()
    }
    
    func setup() {
        displayGrid.applying {
            $0.displayMode = .glyphs
            $0.fullTextBlitter.rootNode.removeFromParentNode()
            $0.fullTextBlitter.backgroundGeometryNode.removeFromParentNode()
            $0.backgroundGeometryNode.categoryBitMask = HitTestType.codeGridControl.rawValue
        }

        displayGrid
            .consume(text: "Swap Mode")
            .sizeGridToContainerNode(pad: 4.0)
            .backgroundColor(NSUIColor(displayP3Red: 0.2, green: 0.4, blue: 0.5, alpha: 0.8))
            .applying { _ = SCNNode.BoundsCaching.Update($0.rootNode, false) }

        displayGrid
            .measures
            .setBottom(targetGrid.measures.top + 2)
            .setLeading(targetGrid.measures.leading)
            .setFront(targetGrid.measures.front)

        didActivate = { [targetGrid] _ in
            switch targetGrid.displayMode {
            case .glyphs:
                targetGrid.displayMode = .layers
            case .layers, .all:
                targetGrid.displayMode = .glyphs
            }
        }
    }
}

class CodeGrid: Identifiable, Equatable {
    
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

// MARK: -- Builder-style configuration
extension CodeGrid {
    func newGridUsingCaches() -> CodeGrid {
        return CodeGrid(
            glyphCache: glyphCache,
            tokenCache: tokenCache
        )
    }
    
    @discardableResult
    func sizeGridToContainerNode(
        pad: VectorFloat = 2.0,
        pivotRootNode: Bool = false
    ) -> CodeGrid {
        laztrace(#fileID,#function,pad,pivotRootNode)
        
        // manualBoundingBox needs to me manually updated after initial layout
        _ = SCNNode.BoundsCaching.Update(rootNode, false)
        
        backgroundGeometry.width = measures.lengthX.cg + pad.cg
        backgroundGeometry.height = measures.lengthY.cg + pad.cg
        
        let centerX = backgroundGeometry.width / 2.0
        let centerY = -backgroundGeometry.height / 2.0
        backgroundGeometryNode.position.x = centerX.vector - pad / 2.0
        backgroundGeometryNode.position.y = centerY.vector + pad / 2.0
        backgroundGeometryNode.position.z = -1
        
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
    
    @discardableResult
    func addingChild(_ child: CodeGrid) -> Self {
        laztrace(#fileID,#function,child)
        rootNode.addChildNode(child.rootNode)
        return self
    }
    
    @discardableResult
    func asChildOf(_ parent: CodeGrid) -> Self {
        laztrace(#fileID,#function,parent)
        parent.rootNode.addChildNode(rootNode)
        return self
    }
}
