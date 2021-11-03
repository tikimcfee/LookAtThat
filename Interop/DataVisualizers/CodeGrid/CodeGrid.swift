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
	lazy var id = UUID().uuidString
	
	let tokenCache: CodeGridTokenCache
	let glyphCache: GlyphLayerCache
	
	let pointer = Pointer()
	let codeGridSemanticInfo: CodeGridSemanticMap = CodeGridSemanticMap()
	let semanticInfoBuilder: SemanticInfoBuilder = SemanticInfoBuilder()
	
	lazy var renderer: CodeGrid.Renderer = CodeGrid.Renderer(targetGrid: self)

	lazy var rootNode: SCNNode = makeContainerNode()
    lazy var gridGeometry: SCNBox = makeGridGeometry()
    lazy var backgroundGeometryNode: SCNNode = SCNNode()
	
	lazy var focusedSynaxGroupId: String = id
	lazy var renderedSyntaxGroups: LockingCache<String, CodeGrid> = .init()
	
    init(_ id: String? = nil,
         glyphCache: GlyphLayerCache,
		 tokenCache: CodeGridTokenCache) {
        self.glyphCache = glyphCache
        self.tokenCache = tokenCache
        self.id = id ?? self.id
    }
    
    public static func == (_ left: CodeGrid, _ right: CodeGrid) -> Bool {
        return left.id == right.id
    }
}

// MARK: -- Builders for lazy properties
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
    func sizeGridToContainerNode(pad: VectorFloat = 2) -> CodeGrid {
        gridGeometry.width = rootNode.lengthX.cg + pad.cg
        gridGeometry.height = rootNode.lengthY.cg + pad.cg
        let centerX = gridGeometry.width / 2.0
        let centerY = -gridGeometry.height / 2.0
        backgroundGeometryNode.position.x = centerX.vector - pad / 2.0
        backgroundGeometryNode.position.y = centerY.vector + pad / 2.0
        backgroundGeometryNode.position.z = -1
        rootNode.pivot = SCNMatrix4MakeTranslation(centerX.vector, centerY.vector, 0)
        return self
    }
}

// MARK: -- Renderer and glyph position
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
		
		let targetGrid: CodeGrid
		private var currentPosition: GlyphPosition { targetGrid.pointer.position }
		
		func insert(
			_ syntaxTokenCharacter: Character,
			_ letterNode: SCNNode, 
			_ size: CGSize
		) {
			// add node directly to root container grid
			letterNode.position = currentPosition.vector
			targetGrid.rootNode.addChildNode(letterNode)
			
			// we're writing left-to-right. 
			// Letter spacing is implicit to layer size.
			targetGrid.pointer.right(size.width)
			if syntaxTokenCharacter.isNewline {
				newLine(size)
			}
		}
		
		func newLine(_ size: CGSize) {
			targetGrid.pointer.down(size.height * Config.newLineSizeRatio)
			targetGrid.pointer.left(currentPosition.xColumn)
		}
	}
}

// CodeSheet operations
private extension SyntaxIdentifier {
	var stringIdentifier: String { "\(hashValue)" }
}

extension CodeGrid {
	// If you call this, you basically draw text like a typewriter from wherevery you last were.
	// it adds caches layer glyphs motivated by display requirements inherited by those clients.
	// 
    @discardableResult
    func consume(syntax: Syntax) -> Self {
		// ## step something other or else: the bits where you tidy up
		// ## - associate this syntax group with a targetable and movable set of glyphs.
		//		glyphs are just nodes with text layers that are rendered from some default font,
		//		otherwise configurable. allows manipulation of code-grid-sub-node-type code grid display layer.
		
		// ## step something or other: stick the actual letters onto the the screen
        for token in syntax.tokens {
			let tokenIdNodeName = token.id.stringIdentifier
			let leadingTriviaNodeName = "\(tokenIdNodeName)-leadingTrivia"
			let trailingTriviaNodeName = "\(tokenIdNodeName)-trailingTrivia"
			
			var leadingTriviaNodes = CodeGridNodes()
			var textNodes = CodeGridNodes()
			var trailingTriviaNodes = CodeGridNodes()
			
			let triviaColor = CodeGridColors.trivia
			let tokenColor = token.defaultColor
			
			for triviaCharacter in token.leadingTrivia.stringified {
				let (letterNode, size) = createNodeFor(triviaCharacter, triviaColor)
				letterNode.name = leadingTriviaNodeName
				leadingTriviaNodes.insert(letterNode)
				renderer.insert(triviaCharacter, letterNode, size)
			}
			
			for textCharacter in token.text {
				let (letterNode, size) = createNodeFor(textCharacter, tokenColor)
				letterNode.name = tokenIdNodeName
				textNodes.insert(letterNode)
				renderer.insert(textCharacter, letterNode, size)
            }

			for triviaCharacter in token.trailingTrivia.stringified {
				let (letterNode, size) = createNodeFor(triviaCharacter, triviaColor)
				letterNode.name = trailingTriviaNodeName
				trailingTriviaNodes.insert(letterNode)
				renderer.insert(triviaCharacter, letterNode, size)
			}
			
			tokenCache[tokenIdNodeName] = textNodes
			tokenCache[leadingTriviaNodeName] = leadingTriviaNodes
			tokenCache[trailingTriviaNodeName] = trailingTriviaNodes
			
			// Walk the parenty hierarchy and associate these nodes with that parent.
			// Add semantic info to lookup for each parent node found
			// NOTE: tokens have no entry in the info set; only their parents are ever added.
//			
//			var tokenParent = token.parent
			var tokenParent: Syntax? = Syntax(token)
			while tokenParent != nil {
				guard let parent = tokenParent else { continue }
				codeGridSemanticInfo.mergeSemanticInfo(
					parent.id,
					token.id.stringIdentifier,
					semanticInfoBuilder.semanticInfo(for: parent)
				)
				codeGridSemanticInfo.mergeSyntaxAssociations(parent, textNodes)
				codeGridSemanticInfo.mergeSyntaxAssociations(parent, leadingTriviaNodes)
				codeGridSemanticInfo.mergeSyntaxAssociations(parent, trailingTriviaNodes)
				tokenParent = parent.parent
			}
        }
		
        return self
    }
	
	private func createNodeFor(
		_ syntaxTokenCharacter: Character,
		_ color: NSUIColor
	) -> (SCNNode, CGSize) {
		let key = GlyphCacheKey("\(syntaxTokenCharacter)", color)
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

extension SCNNode {
	func apply(_ modifier: (SCNNode) -> Void) -> SCNNode {
		modifier(self)
		return self
	}
}
