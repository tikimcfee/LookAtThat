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
    let tokenIdToNodeSetCache: CodeGridTokenCache
	
	let pointer = Pointer()
	let codeGridInfo: CodeGridNodeMap = CodeGridNodeMap()
	let semanticInfoBuilder: SemanticInfoBuilder = SemanticInfoBuilder()
	lazy var renderer: CodeGrid.Renderer = CodeGrid.Renderer(grid: self)
    
    lazy var id = UUID().uuidString
    lazy var rootNode: SCNNode = makeContainerNode()
    lazy var gridGeometry: SCNBox = makeGridGeometry()
    lazy var backgroundGeometryNode: SCNNode = SCNNode()
    let glyphCache: GlyphLayerCache
    
    init(_ id: String? = nil,
         glyphCache: GlyphLayerCache,
		 tokenCache: CodeGridTokenCache) {
        self.glyphCache = glyphCache
		self.tokenIdToNodeSetCache = tokenCache
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

extension CodeGrid {
	struct GlyphPosition: Hashable, Equatable {
		let xColumn: VectorFloat
		let yRow: VectorFloat
		let zDepth: VectorFloat
		var vector: SCNVector3 { SCNVector3(xColumn, yRow, zDepth) }
		
		func transformed(dX: VectorFloat = 0,
						 dY: VectorFloat = 0,
						 dZ: VectorFloat = 0) -> GlyphPosition {
			GlyphPosition(xColumn: xColumn + dX, yRow: yRow + dY, zDepth: zDepth + dZ)
		}
	}
	
	class Pointer {
		var position: GlyphPosition = GlyphPosition(xColumn: 0, yRow: 0, zDepth: 0)
		
		func right(_ dX: VectorFloat) { position = position.transformed(dX: dX) }
		func left(_ dX: VectorFloat) { position = position.transformed(dX: -dX) }
		func up(_ dY: VectorFloat) { position = position.transformed(dY: dY) }
		func down(_ dY: VectorFloat) { position = position.transformed(dY: -dY) }
		func move(to newPosition: GlyphPosition) { position = newPosition }
	}
	
	struct Renderer {
		struct Config {
			static let newLineSizeRatio: VectorFloat = 0.67
		}
		
		let grid: CodeGrid
		var currentPosition: GlyphPosition { grid.pointer.position }
		
		func insert(
			_ syntaxTokenCharacter: Character,
			_ letterNode: SCNNode, 
			_ size: CGSize
		) {
			// add node directly to root container grid
			letterNode.position = currentPosition.vector
			grid.rootNode.addChildNode(letterNode)
			
			// we're writing left-to-right. 
			// Letter spacing is implicit to layer size.
			grid.pointer.right(size.width)
			if syntaxTokenCharacter.isNewline {
				newLine(size)
			}
		}
		
		func newLine(_ size: CGSize) {
			grid.pointer.down(size.height * Config.newLineSizeRatio)
			grid.pointer.left(currentPosition.xColumn)
		}
	}
}

// CodeSheet operations
private extension SyntaxIdentifier {
	var stringIdentifier: String { "\(hashValue)" }
}

extension CodeGrid {
    @discardableResult
    func consume(syntax: Syntax) -> Self {
        for token in syntax.tokens {
			let fullText = token.triviaAndText
			let tokenIdNodeName = token.id.stringIdentifier
			var tokenNodeset = CodeGridNodes()

			for textCharacter in fullText {
				let (letterNode, size) = createNodeFor(textCharacter)
				letterNode.name = tokenIdNodeName
				tokenNodeset.insert(letterNode)
				renderer.insert(textCharacter, letterNode, size)
            }

			tokenIdToNodeSetCache[tokenIdNodeName] = tokenNodeset
			
			// Walk the parenty hierarchy and associate these nodes with that parent.
			// Add semantic info to lookup for each parent node found
			// NOTE: tokens have no entry in the info set; only their parents are ever added.
			var tokenParent = token.parent
			while tokenParent != nil {
				guard let parent = tokenParent else { continue }
				setCodeGridSetSemanticInfo(parent)
				codeGridInfo[parent] = tokenNodeset
				tokenParent = parent.parent
			}
        }
		
        return self
    }
	
	private func setCodeGridSetSemanticInfo(_ syntax: Syntax) {
		guard codeGridInfo.infoCache[syntax.id] == nil else { return } 
		codeGridInfo.infoCache[syntax.id] = semanticInfoBuilder.semanticInfo(for: syntax)
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
}

// associate tokens to sets of nodes.
// { let nodesToUpdate = tracker[someToken] }
// - given a token, return the nodes that represent it
// - use that set to highlight, move, do stuff to

typealias CodeGridNodes = Set<SCNNode>
class CodeGridTokenCache: LockingCache<String, CodeGridNodes> {
	override func make(
		_ key: String, 
		_ store: inout [String : CodeGridNodes]
	) -> CodeGridNodes {
		let set = CodeGridNodes()
		return set
	}
}

typealias AssociationKey = SyntaxIdentifier
class SyntaxNodeAssociationCache: LockingCache<AssociationKey, CodeGridNodes> {
	override func make(
		_ key: AssociationKey, 
		_ store: inout [AssociationKey : CodeGridNodes]
	) -> CodeGridNodes {
		let set = CodeGridNodes()
		return set
	}
}
