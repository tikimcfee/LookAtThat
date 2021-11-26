//
//  CodeGrid.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 10/22/21.
//

import Foundation
import SceneKit
import SwiftSyntax

let kContainerName = "kContainerName"
let kWhitespaceNodeName = "XxX420blazeitspaceXxX"

class CodeGrid: Identifiable, Equatable {
	lazy var id = UUID().uuidString
	
	let tokenCache: CodeGridTokenCache
	let glyphCache: GlyphLayerCache
    
    lazy var fullTextBlitter = CodeGridBlitter(id)
    let fullTextLayerBuilder: FullTextLayerBuilder = FullTextLayerBuilder()
	
	let pointer = Pointer()
	let codeGridSemanticInfo: CodeGridSemanticMap = CodeGridSemanticMap()
	let semanticInfoBuilder: SemanticInfoBuilder = SemanticInfoBuilder()
    
    var displayMode: DisplayMode = .layers {
        willSet { willSetDisplayMode(newValue) }
    }
	
	lazy var renderer: CodeGrid.Renderer = CodeGrid.Renderer(targetGrid: self)

	lazy var rootNode: SCNNode = makeContainerNode()
    lazy var rootGlyphsNode: SCNNode = makeGlyphsContainerNode()
    lazy var gridGeometry: SCNBox = makeGridGeometry()
    lazy var backgroundGeometryNode: SCNNode = SCNNode()
    
    var semanticInfo: SemanticInfo?
	
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

// MARK: -- Displays configuration
extension CodeGrid {
    enum DisplayMode {
        case glyphs
        case layers
    }
    
    private func willSetDisplayMode(_ mode: DisplayMode) {
        guard mode != displayMode else { return }
        print("setting display mode to \(mode)")
        switch mode {
        case .glyphs:
            rootGlyphsNode.isHidden = false
            fullTextBlitter.rootNode.isHidden = true
        case .layers:
            rootGlyphsNode.isHidden = true
            fullTextBlitter.rootNode.isHidden = false
        }
    }
    
    @discardableResult
    func sizeGridToContainerNode(
        pad: VectorFloat = 2,
        pivotRootNode: Bool = false
    ) -> CodeGrid {
        gridGeometry.width = rootNode.lengthX.cg + pad.cg
        gridGeometry.height = rootNode.lengthY.cg + pad.cg
        let centerX = gridGeometry.width / 2.0
        let centerY = -gridGeometry.height / 2.0
        backgroundGeometryNode.position.x = centerX.vector - pad
        backgroundGeometryNode.position.y = centerY.vector + pad
        backgroundGeometryNode.position.z = -1
        // Can help in some layout situations where you want the root node's position
        // to be at dead-center of background geometry
        if pivotRootNode {
            rootNode.pivot = SCNMatrix4MakeTranslation(centerX.vector, centerY.vector, 0)
        }
        return self
    }
    
    @discardableResult
    func translated(dX: VectorFloat = 0,
                    dY: VectorFloat = 0,
                    dZ: VectorFloat = 0) -> CodeGrid {
        rootNode.position = rootNode.position.translated(dX: dX, dY: dY, dZ: dZ)
        return self
    }
    
    @discardableResult
    func backgroundColor(_ color: NSUIColor) -> CodeGrid {
        gridGeometry.firstMaterial?.diffuse.contents = color
        fullTextBlitter.gridGeometry.firstMaterial?.diffuse.contents = color
        return self
    }
}

// MARK: -- Builders for lazy properties
extension CodeGrid {
    private func makeContainerNode() -> SCNNode {
        let container = SCNNode()
        container.name = kContainerName + id
        container.addChildNode(backgroundGeometryNode)
        container.addChildNode(rootGlyphsNode)
        backgroundGeometryNode.geometry = gridGeometry
		backgroundGeometryNode.categoryBitMask = HitTestType.codeGrid.rawValue
        backgroundGeometryNode.name = id
        return container
    }
    
    private func makeGlyphsContainerNode() -> SCNNode {
        let container = SCNNode()
        container.name = "\(kContainerName)-glyphs-\(id)"
        container.categoryBitMask = HitTestType.codeGridGlyphs.rawValue
        return container
    }
    
    private func makeGridGeometry() -> SCNBox {
        let sheetGeometry = SCNBox()
        sheetGeometry.chamferRadius = 4.0
        sheetGeometry.firstMaterial?.diffuse.contents = NSUIColor.black
        sheetGeometry.length = PAGE_EXTRUSION_DEPTH
        return sheetGeometry
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
	
	class Renderer {
		struct Config {
			static let newLineSizeRatio: VectorFloat = 0.67
		}
		
		let targetGrid: CodeGrid
        var lineCount = 0
		private var currentPosition: GlyphPosition { targetGrid.pointer.position }
        
        init(targetGrid: CodeGrid) {
            self.targetGrid = targetGrid
        }

		func insert(
			_ syntaxTokenCharacter: Character,
			_ letterNode: SCNNode, 
			_ size: CGSize
		) {
			// add node directly to root container grid
			letterNode.position = currentPosition.vector
            targetGrid.rootGlyphsNode.addChildNode(letterNode)
			
			// we're writing left-to-right. 
			// Letter spacing is implicit to layer size.
            targetGrid.pointer.right(size.width.vector)
			if syntaxTokenCharacter.isNewline {
				newLine(size)
			}
		}
		
		func newLine(_ size: CGSize) {
            targetGrid.pointer.down(size.height.vector * Config.newLineSizeRatio)
			targetGrid.pointer.left(currentPosition.xColumn)
            lineCount += 1
		}
	}
}

// CodeSheet operations
private extension SyntaxIdentifier {
	var stringIdentifier: String { "\(hashValue)" }
}

extension CodeGrid: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension CodeGrid {
	// If you call this, you basically draw text like a typewriter from wherevery you last were.
	// it adds caches layer glyphs motivated by display requirements inherited by those clients.
    @discardableResult
    func consume(text: String) -> Self {
        func writeAttributedText() {
            func attributedString(_ string: String, _ color: NSUIColor) -> NSAttributedString {
                NSAttributedString(string: string, attributes: [.foregroundColor: color.cgColor])
            }
            let sourceAttributedString = NSMutableAttributedString()
            sourceAttributedString.append(attributedString(text, .white))
            fullTextBlitter.createBackingFlatLayer(fullTextLayerBuilder, sourceAttributedString)
            fullTextBlitter.rootNode.position.z += 2.0
            rootNode.addChildNode(fullTextBlitter.rootNode)
            rootGlyphsNode.isHidden = true
        }
        
        func writeGlyphs() {
            func writeString(_ string: String, _ name: String, _ color: NSUIColor) {
                for newCharacter in string {
                    let (letterNode, size) = createNodeFor(newCharacter, color)
                    letterNode.name = name
                    renderer.insert(newCharacter, letterNode, size)
                }
            }
            writeString(text, text, .white)
            rootGlyphsNode.isHidden = false
        }
        
        switch displayMode {
        case .layers:
            writeAttributedText()
        case .glyphs:
            writeGlyphs()
        }
        
        return self
    }
    
    @discardableResult
    func consume(syntax: Syntax) -> Self {
		// ## step something other or else: the bits where you tidy up
		// ## - associate this syntax group with a targetable and movable set of glyphs.
		//		glyphs are just nodes with text layers that are rendered from some default font,
		//		otherwise configurable. allows manipulation of code-grid-sub-node-type code grid display layer.
		
		// ## step something or other: stick the actual letters onto the the screen
        let sourceAttributedString = NSMutableAttributedString()
        
        for token in syntax.tokens {
			let tokenIdNodeName = token.id.stringIdentifier
			let leadingTriviaNodeName = "\(tokenIdNodeName)-leadingTrivia"
			let trailingTriviaNodeName = "\(tokenIdNodeName)-trailingTrivia"
            let triviaColor = CodeGridColors.trivia
            let tokenColor = token.defaultColor

			var leadingTriviaNodes = CodeGridNodes()
            let leadingTrivia = token.leadingTrivia.stringified

            let tokenText = token.text
            var tokenTextNodes = CodeGridNodes()

            let trailingTrivia = token.trailingTrivia.stringified
			var trailingTriviaNodes = CodeGridNodes()
			
            func writeAttributedText() {
                func attributedString(_ string: String, _ color: NSUIColor) -> NSAttributedString {
                    NSAttributedString(string: string, attributes: [.foregroundColor: color.cgColor])
                }
                
                sourceAttributedString.append(attributedString(leadingTrivia, triviaColor))
                sourceAttributedString.append(attributedString(tokenText, tokenColor))
                sourceAttributedString.append(attributedString(trailingTrivia, triviaColor))
            }
            
            func writeGlyphs() {
                func writeString(_ string: String, _ name: String, _ color: NSUIColor, _ set: inout CodeGridNodes) {
                    for newCharacter in string {
                        let (letterNode, size) = createNodeFor(newCharacter, color)
                        letterNode.name = name
                        set.insert(letterNode)
                        renderer.insert(newCharacter, letterNode, size)
                    }
                }
                
                writeString(leadingTrivia, leadingTriviaNodeName, triviaColor, &leadingTriviaNodes)
                tokenCache[leadingTriviaNodeName] = leadingTriviaNodes
                
                writeString(tokenText, tokenIdNodeName, tokenColor, &tokenTextNodes)
                tokenCache[tokenIdNodeName] = tokenTextNodes
                
                writeString(trailingTrivia, trailingTriviaNodeName, triviaColor, &trailingTriviaNodes)
                tokenCache[trailingTriviaNodeName] = trailingTriviaNodes
            }
            
            func walkHierarchyForSemantics() {
                // Walk the parenty hierarchy and associate these nodes with that parent.
                // Add semantic info to lookup for each parent node found.
                var tokenParent: Syntax? = Syntax(token)
                while tokenParent != nil {
                    guard let parent = tokenParent else { continue }
                    codeGridSemanticInfo.mergeSemanticInfo(
                        parent.id,
                        token.id.stringIdentifier,
                        semanticInfoBuilder.semanticInfo(for: parent)
                    )
                    tokenTextNodes.formUnion(leadingTriviaNodes)
                    tokenTextNodes.formUnion(trailingTriviaNodes)
                    codeGridSemanticInfo.mergeSyntaxAssociations(parent, tokenTextNodes)
                    //                codeGridSemanticInfo.mergeSyntaxAssociations(parent, leadingTriviaNodes)
                    //                codeGridSemanticInfo.mergeSyntaxAssociations(parent, trailingTriviaNodes)
                    tokenParent = parent.parent
                }
            }
            
            switch displayMode {
            case .layers: writeAttributedText()
            case .glyphs: writeGlyphs()
            }
            
//            walkHierarchyForSemantics()
        }
        
        switch displayMode {
        case .layers:
            fullTextBlitter.createBackingFlatLayer(fullTextLayerBuilder, sourceAttributedString)
            fullTextBlitter.rootNode.position.z += 2.0
            rootNode.addChildNode(fullTextBlitter.rootNode)
            rootGlyphsNode.isHidden = true
        case .glyphs:
            rootGlyphsNode.isHidden = false
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

class CodeGridEmpty: CodeGrid {
    static let emptyGlyphCache = GlyphLayerCache()
    static let emptyTokenCache = CodeGridTokenCache()
    static func make() -> CodeGrid {
        CodeGrid(
            glyphCache: emptyGlyphCache,
            tokenCache: emptyTokenCache
        )
    }
}
