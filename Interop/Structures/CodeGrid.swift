//
//  CodeGrid.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 10/22/21.
//

import Foundation
import SceneKit
import SwiftSyntax

class CodeGrid: Identifiable, Equatable {
    struct GlyphPosition: Hashable, Equatable {
        let xColumn: VectorFloat
        let yRow: VectorFloat
        let zDepth: VectorFloat
        
        func transformed(dX: VectorFloat = 0,
                         dY: VectorFloat = 0,
                         dZ: VectorFloat = 0) -> GlyphPosition {
            GlyphPosition(xColumn: xColumn + dX, yRow: yRow + dY, zDepth: zDepth + dZ)
        }
        
        lazy var vector: SCNVector3 = { SCNVector3(xColumn, yRow, zDepth) }()
    }
    
    class Pointer {
        var position: GlyphPosition = GlyphPosition(xColumn: 0, yRow: 0, zDepth: 0)
        
        func right(_ dX: VectorFloat) { position = position.transformed(dX: dX) }
        func left(_ dX: VectorFloat) { position = position.transformed(dX: -dX) }
        func up(_ dY: VectorFloat) { position = position.transformed(dY: dY) }
        func down(_ dY: VectorFloat) { position = position.transformed(dY: -dY) }
        func move(to position: GlyphPosition) { self.position = position }
    }
    
    let pointer = Pointer()
    var nodes = [GlyphPosition: SCNNode]()
    var size = GlyphPosition(xColumn: 100, yRow: 100, zDepth: 0)
    
    lazy var id = UUID().uuidString
    lazy var rootNode: SCNNode = makeContainerNode()
    lazy var gridGeometry: SCNBox = makePageGeometry()
    lazy var backgroundGeometryNode: SCNNode = SCNNode()
    let glyphCache: GlyphLayerCache
    
    init(_ id: String? = nil,
         glyphCache: GlyphLayerCache) {
        self.glyphCache = glyphCache
        self.id = id ?? self.id
    }
    
    public static func == (_ left: CodeGrid, _ right: CodeGrid) -> Bool {
        return left.id == right.id
    }
}

extension CodeGrid {
    private func makeContainerNode() -> SCNNode {
        let container = SCNNode()
        container.name = kContainerName + UUID().uuidString
        container.addChildNode(backgroundGeometryNode)
        backgroundGeometryNode.geometry = gridGeometry
        backgroundGeometryNode.categoryBitMask = HitTestType.codeSheet.rawValue
        backgroundGeometryNode.name = id
        return container
    }
    
    private func makePageGeometry() -> SCNBox {
        let sheetGeometry = SCNBox()
        sheetGeometry.chamferRadius = 4.0
        sheetGeometry.firstMaterial?.diffuse.contents = NSUIColor.black
        sheetGeometry.length = PAGE_EXTRUSION_DEPTH
        return sheetGeometry
    }
    
    @discardableResult
    func sizeGridToContainerNode(pad: VectorFloat = 0) -> CodeGrid {
        gridGeometry.width = rootNode.lengthX.cg + pad.cg
        gridGeometry.height = rootNode.lengthY.cg + pad.cg
        let centerX = gridGeometry.width / 2.0
        let centerY = -gridGeometry.height / 2.0
        backgroundGeometryNode.position.x = centerX.vector
        backgroundGeometryNode.position.y = centerY.vector
        backgroundGeometryNode.position.z = -1
        rootNode.pivot = SCNMatrix4MakeTranslation(centerX.vector, centerY.vector, 0)
        return self
    }
}

// CodeSheet operations
extension CodeGrid {
    @discardableResult
    func consume(syntax: Syntax) -> Self {
        for token in syntax.tokens {
            let fullText = token.triviaAndText
            for textCharacter in fullText {
                onConsumeLayoutGlyph(textCharacter)
            }
        }
        return self
    }
    
    private func onConsumeLayoutGlyph(_ textCharacter: Character) {
        let key = GlyphCacheKey("\(textCharacter)", NSUIColor.white)
        let (geometry, size) = glyphCache[key]
        
        let letterNode = SCNNode()
        letterNode.position = pointer.position.vector
        letterNode.geometry = geometry
        
        let centerX = size.width / 2.0
        let centerY = -size.height / 2.0
        let pivotCenterToLeadingTop = SCNMatrix4MakeTranslation(-centerX.vector, -centerY.vector, 0)
        letterNode.pivot = pivotCenterToLeadingTop
        
        rootNode.addChildNode(letterNode)
        pointer.right(size.width)
        if textCharacter.isNewline {
            pointerNewLine(size)
        }
    }
    
    private func pointerNewLine(_ size: CGSize) {
        pointer.down(size.height)
        pointer.left(pointer.position.xColumn)
    }
}
