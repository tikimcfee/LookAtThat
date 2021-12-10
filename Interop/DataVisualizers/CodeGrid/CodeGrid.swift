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
    
    private(set) var codeGridSemanticInfo: CodeGridSemanticMap = CodeGridSemanticMap()
    let semanticInfoBuilder: SemanticInfoBuilder = SemanticInfoBuilder()
    
    var walkSemantics: Bool = Defaults.walkSemantics
    var displayMode: DisplayMode = Defaults.displayMode {
        willSet { willSetDisplayMode(newValue) }
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

// MARK: -- CodeClones
extension CodeGrid {
    func makeClone() -> CodeGrid {
        let clone = CodeGrid(
            cloneId,
            glyphCache: glyphCache,
            tokenCache: tokenCache
        )
        clone.codeGridSemanticInfo = codeGridSemanticInfo
        
        clone.rootNode = rootNode.clone()
        clone.rootNode.name = clone.id
        guard let clonedGlyphes = clone.rootNode.childNode(withName: glyphNodeName, recursively: false),
              let clonedBackground = clone.rootNode.childNode(withName: backgroundNodeName, recursively: false),
              let clonedGeometry = clonedBackground.geometry?.deepCopy() as? SCNBox
        else {
            fatalError("Node cloning failed - did not find child nodes")
        }
        clone.rootGlyphsNode = clonedGlyphes
        clone.rootGlyphsNode.name = clone.glyphNodeName
        clone.backgroundGeometryNode = clonedBackground
        clone.backgroundGeometryNode.name = clone.backgroundNodeName
        clone.backgroundGeometry = clonedGeometry
        clone.backgroundGeometryNode.geometry = clone.backgroundGeometry
        // TODO: add the full text stuff as well
        
        guard let fullTextNode = clone.rootNode.childNode(withName: fullTextBlitter.id, recursively: false)
        else {
            fatalError("Node cloning failed - full text blitter missing")
        }
        fullTextNode.removeFromParentNode()
        
        return clone
    }
}

// MARK: -- Displays configuration
extension CodeGrid {
    enum DisplayMode {
        case glyphs
        case layers
        case all
    }
    
    private func willSetDisplayMode(_ mode: DisplayMode) {
        laztrace(#fileID,#function,mode)
        guard mode != displayMode else { return }
        print("setting display mode to \(mode)")
        switch mode {
        case .glyphs:
            rootGlyphsNode.isHidden = false
            fullTextBlitter.rootNode.isHidden = true
        case .layers:
            rootGlyphsNode.isHidden = true
            fullTextBlitter.rootNode.isHidden = false
        case .all:
            rootGlyphsNode.isHidden = false
            fullTextBlitter.rootNode.isHidden = false
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

// CodeSheet operations
extension CodeGrid: Hashable {
    func hash(into hasher: inout Hasher) {
        laztrace(#fileID,#function,hasher)
        hasher.combine(id)
    }
}

extension CodeGrid {
    // If you call this, you basically draw text like a typewriter from wherevery you last were.
    // it adds caches layer glyphs motivated by display requirements inherited by those clients.
    @discardableResult
    func consume(text: String) -> Self {
        laztrace(#fileID,#function,text)
        func writeAttributedText() {
            func attributedString(_ string: String, _ color: NSUIColor) -> NSAttributedString {
                NSAttributedString(string: string, attributes: [.foregroundColor: color.cgColor])
            }
            let sourceAttributedString = NSMutableAttributedString()
            sourceAttributedString.append(attributedString(text, .white))
            fullTextBlitter.createBackingFlatLayer(fullTextLayerBuilder, sourceAttributedString)
            fullTextBlitter.rootNode.position.z += 2.0
            rootNode.addChildNode(fullTextBlitter.rootNode)
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
        }
        
        switch displayMode {
        case .layers:
            writeAttributedText()
            fullTextBlitter.rootNode.isHidden = false
            rootGlyphsNode.isHidden = true
        case .glyphs:
            writeGlyphs()
            fullTextBlitter.rootNode.isHidden = true
            rootGlyphsNode.isHidden = false
        case .all:
            writeAttributedText()
            writeGlyphs()
            fullTextBlitter.rootNode.isHidden = false
            rootGlyphsNode.isHidden = true
        }
        
        return self
    }
    
    @discardableResult
    func consume(syntax: Syntax) -> Self {
        laztrace(#fileID,#function,syntax)
        // ## step something other or else: the bits where you tidy up
        // ## - associate this syntax group with a targetable and movable set of glyphs.
        //        glyphs are just nodes with text layers that are rendered from some default font,
        //        otherwise configurable. allows manipulation of code-grid-sub-node-type code grid display layer.
        
        // ## step something or other: stick the actual letters onto the the screen
        let sourceAttributedString = NSMutableAttributedString()
        
        for token in syntax.tokens {
            let tokenId = token.id
            let tokenIdNodeName = tokenId.stringIdentifier
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
                    let parentId = parent.id
                    codeGridSemanticInfo.saveSemanticInfo(
                        parentId,
                        tokenIdNodeName,
                        semanticInfoBuilder.semanticInfo(for: parent)
                    )
                    codeGridSemanticInfo.associate(
                        syntax: parent,
                        withLookupId: tokenId
                    )
                    tokenParent = parent.parent
                }
            }
            
            switch displayMode {
            case .layers:
                writeAttributedText()
            case .glyphs:
                writeGlyphs()
            case .all:
                writeAttributedText()
                writeGlyphs()
            }
            if walkSemantics {
                walkHierarchyForSemantics()
            }
        }
        
        switch displayMode {
        case .layers, .all:
            fullTextBlitter.createBackingFlatLayer(fullTextLayerBuilder, sourceAttributedString)
            fullTextBlitter.rootNode.position.z += 2.0
            rootNode.addChildNode(fullTextBlitter.rootNode)
            
            fullTextBlitter.rootNode.isHidden = false
            rootGlyphsNode.isHidden = true
        case .glyphs:
            fullTextBlitter.rootNode.isHidden = true
            rootGlyphsNode.isHidden = false
        }
        
        return self
    }
    
    private func createNodeFor(
        _ syntaxTokenCharacter: Character,
        _ color: NSUIColor
    ) -> (SCNNode, CGSize) {
        laztrace(#fileID,#function,syntaxTokenCharacter,color)
        let key = GlyphCacheKey("\(syntaxTokenCharacter)", color)
        let (geometry, size) = glyphCache[key]
        
        let letterNode = SCNNode()
        letterNode.geometry = geometry
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
        laztrace(#fileID,#function,key,store)
        let set = CodeGridNodes()
        return set
    }
}

extension SCNNode {
    func simdTranslate(dX: VectorFloat = 0, dY: VectorFloat = 0, dZ: VectorFloat = 0) {
        simdPosition += simdWorldRight * Float(dX)
        simdPosition += simdWorldUp * Float(dY)
        simdPosition += simdWorldFront * Float(dZ)
    }
    
    func apply(_ modifier: @escaping (SCNNode) -> Void) -> SCNNode {
        laztrace(#fileID,#function,modifier)
        modifier(self)
        return self
    }
}

class CodeGridEmpty: CodeGrid {
    static let emptyGlyphCache = GlyphLayerCache()
    static let emptyTokenCache = CodeGridTokenCache()
    static func make() -> CodeGrid {
        laztrace(#fileID,#function)
        return CodeGrid(
            glyphCache: emptyGlyphCache,
            tokenCache: emptyTokenCache
        )
    }
}
