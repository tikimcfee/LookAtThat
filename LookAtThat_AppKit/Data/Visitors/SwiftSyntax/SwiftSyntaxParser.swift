import Foundation
import SwiftSyntax
import SceneKit

public struct SourceInfo {
    var tokenTypes = [String]()

    var identifiers = Set<String>()
    var strings = Set<String>()
    var numbers = Set<String>()

    var allTokens = AutoListValueDict<String, String>()
    var sortedTokens: [(String, [String])] {
        return allTokens.map.sorted { leftPair, rightPair in
            return leftPair.key <= rightPair.key
        }
    }
}

// SwiftSyntax
class SwiftSyntaxParser: SyntaxRewriter {

    var textNodeBuilder: WordNodeBuilder
    var resultInfo = SourceInfo()

    init(iterator: WordPositionIterator,
         wordNodeBuilder: WordNodeBuilder) {
        self.textNodeBuilder = wordNodeBuilder
        super.init()
    }

    override func visit(_ functionDeclarationNode: FunctionDeclSyntax) -> DeclSyntax {
        return super.visit(functionDeclarationNode)
    }
}

// File loading
extension SwiftSyntaxParser {
    func requestSourceFile(_ receiver: @escaping (URL) -> Void) {
        openFile { fileReslt in
            switch fileReslt {
            case let .success(url):
                receiver(url)
            case let .failure(error):
                print(error)
            }
        }
    }

    func loadSourceUrl(_ url: URL) -> SourceFileSyntax? {
        do {
            return try SyntaxParser.parse(url)
        } catch {
            print("|\(url)| failed to load > \(error)")
            return nil
        }
    }
}

// Node building
extension SwiftSyntaxParser {
    func renderNodes(_ fileUrl: URL) -> SourceInfo {
        guard let sourceFileSyntax = loadSourceUrl(fileUrl)
            else { return SourceInfo() }
        resultInfo = SourceInfo()

        let rootSyntax = visit(sourceFileSyntax)
        print("Rendering \(fileUrl)})")

        let codeSheet = CodeSheet()
        codeSheet.containerNode.position =
            codeSheet.containerNode.position.translated(dZ: nextZ - 100)

        for token in rootSyntax.tokens {
            iterateTrivia(token.leadingTrivia, token, codeSheet)
            arrange(token.text, token, codeSheet)
            iterateTrivia(token.trailingTrivia, token, codeSheet)
        }

        codeSheet.sizePageToContainerNode()

        sceneTransaction {
            MainSceneController.global.sceneState
                .rootGeometryNode.addChildNode(codeSheet.containerNode)
        }

        return resultInfo
    }

    private func arrange(_ text: String,
                         _ token: TokenSyntax,
                         _ codeSheet: CodeSheet) {
        let newNode = textNodeBuilder.node(for: text)
        newNode.name = token.registeredName(in: &resultInfo)
        [newNode].arrangeInLine(on: codeSheet.lastLine)
    }

    private func iterateTrivia(_ trivia: Trivia,
                               _ token: TokenSyntax,
                               _ codeSheet: CodeSheet) {
        for triviaPiece in trivia {
            if case TriviaPiece.newlines(let count) = triviaPiece {
                codeSheet.newlines(count)
            } else {
                arrange(triviaPiece.stringify, token, codeSheet)
            }
        }
    }
}

class CodeSheet {

    lazy var sheetName = UUID().uuidString
    lazy var allLines = [SCNNode]()
    lazy var iteratorY = WordPositionIterator()

    lazy var pageGeometry: SCNBox = {
        let sheetGeometry = SCNBox()
        sheetGeometry.firstMaterial?.diffuse.contents = NSUIColor.black
        sheetGeometry.length = PAGE_EXTRUSION_DEPTH
        return sheetGeometry
    }()

    lazy var pageGeometryNode = SCNNode()

    lazy var containerNode: SCNNode = {
        let container = SCNNode()
        container.addChildNode(pageGeometryNode)
        pageGeometryNode.categoryBitMask = HitTestType.codeSheet
        pageGeometryNode.geometry = pageGeometry
        return container
    }()

    lazy var lastLine: SCNNode = {
        // The scene geometry at the end is off by a line. This will probably be an issue at some point.
        let line = SCNNode()
        line.position = SCNVector3(0, iteratorY.nextLineY(), PAGE_EXTRUSION_DEPTH)
        containerNode.addChildNode(line)
        return line
    }()

    func newlines(_ count: Int) {
        for _ in 0..<count {
            setNewLine()
        }
    }

    func sizePageToContainerNode() {
        pageGeometry.width = containerNode.lengthX
        pageGeometry.height = containerNode.lengthY
        pageGeometryNode.simdPosition.y = -Float(pageGeometry.height / 2)
        pageGeometryNode.simdPosition.x = Float(pageGeometry.width / 2)
    }

    private func setNewLine() {
        let newLine = SCNNode()
        newLine.position = lastLine.position.translated(
            dY: -iteratorY.linesPerBlock
        )
        allLines.append(newLine)
        lastLine = newLine
        containerNode.addChildNode(newLine)
    }
}

extension simd_float4x4 {
    init(translation vector: SIMD3<Float>) {
        self.init(SIMD4<Float>(1, 0, 0, 0),
                  SIMD4<Float>(0, 1, 0, 0),
                  SIMD4<Float>(0, 0, 1, 0),
                  SIMD4<Float>(vector.x, vector.y, vector.z, 1)
        )
    }
}
