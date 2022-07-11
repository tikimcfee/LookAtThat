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
    #elseif CherrieiSkip
    struct Defaults {
        static var displayMode: DisplayMode = .glyphs
        static var walkSemantics: Bool = false
    }
    #else
    struct Defaults {
        static var displayMode: DisplayMode = .glyphs
        static var walkSemantics: Bool = true
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

public class CodeGrid: Identifiable, Equatable {
    
    public lazy var id = { "\(kCodeGridContainerName)-\(UUID().uuidString)" }()
    lazy var rootContainerNodeName = { "\(id)-container" }()
    lazy var glyphNodeName = { "\(id)-glyphs" }()
    lazy var flattedGlyphNodeName = { "\(id)-glyphs-flattened" }()
    lazy var backgroundNodeName = { "\(id)-background" }()
    lazy var backgroundNodeGeometry = { "\(id)-background-geometry" }()
    var cloneId: ID { "\(id)-clone" }
    var fileName: String = ""
    var sourcePath: URL?
    private(set) var glyphSwapLocked = false // transient switch to disallow swapping
    private(set) var showingRawGlyphs = true // start with true, finalize() will flatten and set first
    private(set) var lockLevel = 0
    
    let tokenCache: CodeGridTokenCache
    let glyphCache: GlyphLayerCache
    
    var consumedRootSyntaxNodes: [Syntax] = []
    var codeGridSemanticInfo: CodeGridSemanticMap = CodeGridSemanticMap()
    let semanticInfoBuilder: SemanticInfoBuilder = SemanticInfoBuilder()
    
    lazy var rawGlyphWriter: RawGlyphs = {
        return RawGlyphs(self)
    }()
    
    lazy var attributedGlyphsWriter: AttributedGlyphs = {
        return AttributedGlyphs(self)
    }()
    
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
        sheetGeometry.length = 0.75
        return sheetGeometry
    }
}

// MARK: -- Hashing
extension CodeGrid: Hashable {
    public func hash(into hasher: inout Hasher) {
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
    
    @discardableResult
    func withSourcePath(_ filePath: URL) -> Self {
        self.sourcePath = filePath
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
    
    func lockGlyphSwapping() {
        glyphSwapLocked = true
    }
    
    func incrementLock() {
        if lockLevel == 0 {
            lockGlyphSwapping()
        }
        lockLevel += 1
    }
    
    func decrementLock() {
        lockLevel -= 1
        if lockLevel == 0 {
            unlockGlyphSwapping()
        }
    }
    
    func unlockGlyphSwapping() {
        glyphSwapLocked = false
    }
    
    func swapInRootGlyphs(
        _ function: String = #function,
        _ line: Int = #line
    ) {
        if glyphSwapLocked { return }
        guard !showingRawGlyphs else {
            print("Unneeded node swap from \(function)::\(line)")
            return
        }
        
        rootContainerNode.childNode(
            withName: glyphNodeName,
            recursively: false
        )?.removeFromParentNode()
        rootContainerNode.addChildNode(rawGlyphsNode)
        rawGlyphsNode.isHidden = false
        showingRawGlyphs = true
        flattenedGlyphsNode?.isHidden = true
    }
    
    func swapOutRootGlyphs(
        _ function: String = #function,
        _ line: Int = #line
    ) {
        if glyphSwapLocked { return }
        guard showingRawGlyphs else {
            print("Unneeded node swap from \(function)::\(line)")
            return
        }
        
        let new = SCNNode()
        new.name = rawGlyphsNode.name
        rootContainerNode.replaceChildNode(rawGlyphsNode, with: new)
        rawGlyphsNode.isHidden = true
        showingRawGlyphs = false
        flattenedGlyphsNode?.isHidden = false
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
