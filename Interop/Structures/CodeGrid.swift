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
	let tokenCache = CodeGridTokenCache()
    
    lazy var id = UUID().uuidString
    lazy var rootNode: SCNNode = makeContainerNode()
    lazy var gridGeometry: SCNBox = makeGridGeometry()
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
		backgroundGeometryNode.categoryBitMask = HitTestType.codeGrid.rawValue
        backgroundGeometryNode.name = id
        return container
    }
    
    private func makeGridGeometry() -> SCNBox {
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

extension SyntaxIdentifier {
	var stringIdentifier: String { "\(hashValue)" }
}

// CodeSheet operations
extension CodeGrid {
    @discardableResult
    func consume(syntax: Syntax) -> Self {
        for token in syntax.tokens {
			let fullText = token.triviaAndText
			let tokenId = token.id.stringIdentifier
			var tokenNodeset = Nodeset()
			
			var associationId = 0
			for textCharacter in fullText {
				let (letterNode, size) = createNodeFor(textCharacter)
				letterNode.name = "\(tokenId)-\(associationId)"
				pointerAddToGrid(textCharacter, letterNode, size)
				
				associationId += 1
				tokenNodeset.insert(letterNode)
            }

			tokenCache[token.id] = tokenNodeset
        }
        return self
    }
	
	private func createNodeFor(_ syntaxTokenCharacter: Character) -> (SCNNode, CGSize) {
		let key = GlyphCacheKey("\(syntaxTokenCharacter)", NSUIColor.white) // TODO: colorizer fits in here somewhere
		let (geometry, size) = glyphCache[key]
		
		
		let centerX = size.width / 2.0
		let centerY = -size.height / 2.0
		let pivotCenterToLeadingTop = SCNMatrix4MakeTranslation(-centerX.vector, -centerY.vector, 0)
		
		let letterNode = SCNNode()
		letterNode.geometry = geometry
		letterNode.pivot = pivotCenterToLeadingTop
		letterNode.categoryBitMask = HitTestType.codeGridToken.rawValue
		
		return (letterNode, size)
	}
	
	private func pointerAddToGrid(
		_ syntaxTokenCharacter: Character,
		_ letterNode: SCNNode, 
		_ size: CGSize
	) {
		// add node directly to root container grid
		letterNode.position = pointer.position.vector
		rootNode.addChildNode(letterNode)
		
		// we're writing left-to-right. 
		// Letter spacing is implicit to layer size.
		pointer.right(size.width)
		if syntaxTokenCharacter.isNewline {
			pointerNewLine(size)
		}
	}
    
    private func pointerNewLine(_ size: CGSize) {
        pointer.down(size.height)
        pointer.left(pointer.position.xColumn)
    }
}

// associate tokens to sets of nodes.
// { let nodesToUpdate = tracker[someToken] }
// - given a token, return the nodes that represent it
// - use that set to highlight, move, do stuff to

typealias Nodeset = Set<SCNNode>

class CodeGridTokenCache: LockingCache<SyntaxIdentifier, Nodeset> {
	override func make(
		_ key: SyntaxIdentifier, 
		_ store: inout [SyntaxIdentifier : Nodeset]
	) -> Nodeset {
		let set = Nodeset()
		return set
	}
}
