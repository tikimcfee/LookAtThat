import Foundation
import SwiftSyntax
import SceneKit

public class SourceInfo {
    var tokenTypes = [String]()

    var identifiers = Set<String>()
    var strings = Set<String>()
    var numbers = Set<String>()

    var functions = AutoListValueDict<String, FunctionDeclSyntax>()
    var enums = AutoListValueDict<String, EnumDeclSyntax>()
    var closures = AutoListValueDict<String, ClosureExprSyntax>()
    var extensions = AutoListValueDict<String, ExtensionDeclSyntax>()
    var structs = AutoListValueDict<String, StructDeclSyntax>()

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

    init(wordNodeBuilder: WordNodeBuilder) {
        self.textNodeBuilder = wordNodeBuilder
        super.init()
    }

    override func visit(_ node: FunctionDeclSyntax) -> DeclSyntax {
        resultInfo.functions[node.identifier.alltext].append(node)
        return super.visit(node)
    }

    override func visit(_ node: EnumDeclSyntax) -> DeclSyntax {
        resultInfo.enums[node.identifier.alltext].append(node)
        return super.visit(node)
    }

    override func visit(_ node: ClosureExprSyntax) -> ExprSyntax {
        resultInfo.closures[node.firstToken?.alltext ?? "Closure \(node.id.hashValue)"].append(node)
        return super.visit(node)
    }

    override func visit(_ node: ExtensionDeclSyntax) -> DeclSyntax {
        resultInfo.extensions[node.extendedType.firstToken!.alltext].append(node)
        return super.visit(node)
    }

    override func visit(_ node: StructDeclSyntax) -> DeclSyntax {
        resultInfo.structs[node.identifier.alltext].append(node)
        return super.visit(node)
    }
}

// Node building
extension SwiftSyntaxParser {
    func renderTokenSection() {

    }

    func render(source fileUrl: URL, in sceneState: SceneState) {
        guard let sourceFileSyntax = loadSourceUrl(fileUrl)
            else { return }
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
            sceneState.rootGeometryNode.addChildNode(codeSheet.containerNode)
        }
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
            switch triviaPiece {
            case let .newlines(count):
                codeSheet.newlines(count)
            case let .blockComment(comment),
                 let .docBlockComment(comment):
                comment
                    .split(whereSeparator: { $0.isNewline })
                    .forEach{
                        arrange(String($0), token, codeSheet)
                        codeSheet.newlines(1)
                    }
            default:
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
        sheetGeometry.chamferRadius = 4.0
//        sheetGeometry.firstMaterial?.metalness.contents = 0.5
//        sheetGeometry.firstMaterial?.roughness.contents = NSUIColor.darkGray
//        sheetGeometry.firstMaterial?.lightingModel = .physicallyBased
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
        let centerY = -pageGeometry.height / 2
        let centerX = pageGeometry.width / 2
        pageGeometryNode.position.y = centerY
        pageGeometryNode.position.x = centerX
        containerNode.pivot = SCNMatrix4MakeTranslation(centerX, centerY, 0);
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

// File loading
extension SwiftSyntaxParser {
    func requestSourceDirectory(_ receiver: @escaping (Directory) -> Void) {
        openDirectory { directoryResult in
            switch directoryResult {
            case let .success(directory):
                receiver(directory)
            case let .failure(error):
                print(error)
            }
        }
    }

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
