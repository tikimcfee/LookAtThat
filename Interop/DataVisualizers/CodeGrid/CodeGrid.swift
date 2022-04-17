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
        static var displayMode: DisplayMode = .glyphs
        static var walkSemantics: Bool = true
    }
    #else
    struct Defaults {
        static var displayMode: DisplayMode = .glyphs
        static var walkSemantics: Bool = true
    }
    #endif
}

extension CodeGrid: CustomStringConvertible {
    var description: String {
"""
CodeGrid(\(id.trimmingCharacters(in: CharacterSet(charactersIn: kCodeGridContainerName)))
""".trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

class CodeGrid: Identifiable, Equatable {
    
    lazy var id = { "\(kCodeGridContainerName)-\(UUID().uuidString)" }()
    lazy var rootContainerNodeName = { "\(id)-container" }()
    lazy var glyphNodeName = { "\(id)-glyphs" }()
    lazy var flattedGlyphNodeName = { "\(id)-glyphs-flattened" }()
    lazy var backgroundNodeName = { "\(id)-background" }()
    lazy var backgroundNodeGeometry = { "\(id)-background-geometry" }()
    var cloneId: ID { "\(id)-clone" }
    var fileName: String = ""
    private var showingRawGlyphs = false
    
    let tokenCache: CodeGridTokenCache
    let glyphCache: GlyphLayerCache
    
    lazy var fullTextBlitter: CodeGridBlitter = CodeGridBlitter(id)
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
    lazy var rootContainerNode: SCNNode = makeRootContainerNode()
    lazy var rawGlyphsNode: SCNNode = makeRootGlyphsNode()
    lazy var flattenedGlyphsNode: SCNNode? = nil
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
        let root = SCNNode()
        root.name = id
        root.addChildNode(rootContainerNode)
        return root.withDeviceScale()
    }
    
    private func makeRootContainerNode() -> SCNNode {
        laztrace(#fileID,#function)
        let container = SCNNode()
        container.name = rootContainerNodeName
        container.addChildNode(rawGlyphsNode)
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
        sheetGeometry.name = backgroundNodeGeometry
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
    @discardableResult
    func sizeGridToContainerNode(
        pad: VectorFloat = 2.0,
        pivotRootNode: Bool = false
    ) -> CodeGrid {
        laztrace(#fileID,#function,pad,pivotRootNode)
        
        let zStart = VectorFloat(2.0)
        let unscaledWidth = measures.lengthX.cg * DeviceScaleInverse.cg
        let unscaledHeight = measures.lengthY.cg * DeviceScaleInverse.cg
                
        backgroundGeometry.width = unscaledWidth + pad.cg
        backgroundGeometry.height = unscaledHeight + pad.cg
        
        let centerX = backgroundGeometry.width / 2.0
        let centerY = -backgroundGeometry.height / 2.0
        
        backgroundGeometryNode.pivot = SCNMatrix4Translate(
//            backgroundGeometryNode.pivot, // so... using pivot only worked because it starts at identity. oops.
            SCNMatrix4Identity,
            -(centerX.vector - pad / 2.0),
            -(centerY.vector + pad / 2.0),
            (zStart)
        )
        
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
    func transparentBackgroundColor(_ color: NSUIColor,
                                    transparency: CGFloat = 0.40,
                                    mode: SCNTransparencyMode = .dualLayer) -> CodeGrid {
        laztrace(#fileID,#function,color)
        if let material = backgroundGeometry.firstMaterial {
            material.diffuse.contents = color
            material.transparency = transparency
            material.transparencyMode = mode
        }
        if let material = fullTextBlitter.gridGeometry.firstMaterial {
            material.diffuse.contents = color
            material.transparency = transparency
            material.transparencyMode = mode
        }
        return self
    }
    
    @discardableResult
    func applying(_ action: (Self) -> Void) -> Self {
        laztrace(#fileID,#function)
        action(self)
        return self
    }
    
    @discardableResult
    func addingChild(_ child: CodeGridControl) -> Self {
        laztrace(#fileID,#function,child)
        rootContainerNode.addChildNode(child.displayGrid.rootNode)
        return self
    }
    
    @discardableResult
    func addingChild(_ child: CodeGrid) -> Self {
        laztrace(#fileID,#function,child)
        rootContainerNode.addChildNode(child.rootNode)
        return self
    }
    
    @discardableResult
    func asChildOf(_ parent: CodeGrid) -> Self {
        laztrace(#fileID,#function,parent)
        parent.rootContainerNode.addChildNode(rootNode)
        return self
    }
    
    @discardableResult
    func asChildOf(_ parent: SCNNode) -> Self {
        laztrace(#fileID,#function,parent)
        parent.addChildNode(rootNode)
        return self
    }
    
    @discardableResult
    func withFileName(_ fileName: String) -> Self {
        self.fileName = fileName
        return self
    }
}

extension CodeGrid {
    func toggleGlyphs() {
        if showingRawGlyphs {
            swapOutRootGlyphs()
        } else {
            swapInRootGlyphs()
        }
    }
    
    func swapInRootGlyphs() {
        rootContainerNode.childNode(
            withName: glyphNodeName,
            recursively: false
        )?.removeFromParentNode()
        rootContainerNode.addChildNode(rawGlyphsNode)
        rawGlyphsNode.isHidden = false
        showingRawGlyphs = true
    }
    
    func swapOutRootGlyphs() {
        let new = SCNNode()
        new.name = rawGlyphsNode.name
        rootContainerNode.replaceChildNode(rawGlyphsNode, with: new)
        rawGlyphsNode.isHidden = true
        showingRawGlyphs = false
    }
    
    @discardableResult
    func flattenRootGlyphNode() -> Self {
        laztrace(#fileID,#function)
        
        let flattened = rawGlyphsNode.flattenedClone()
        flattened.name = flattedGlyphNodeName
        flattenedGlyphsNode = flattened
        rootContainerNode.addChildNode(flattened)
        
        swapOutRootGlyphs()
        return self
    }
}
