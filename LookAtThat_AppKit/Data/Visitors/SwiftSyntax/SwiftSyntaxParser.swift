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
//        print("---------------------------------------")
//        print("Found a function: \(node.identifier)")
//        print(
//"""
//\(node.attributes)
//\(node.modifiers)
//\(node.genericParameterClause)
//\(node.signature)
//\(node.genericWhereClause)
//\(node.body?.statements.forEach{ print($0) })
//"""
//        )
//        let functionText = node.tokens.reduce(into: "") { buffer, token in
//            buffer.append(token.alltext)
//        }
//        print(functionText)



//        for token in functionDeclarationNode.tokens {
//            iterateTrivia(token.leadingTrivia, token)
//            arrange(token.text, token)
//            iterateTrivia(token.trailingTrivia, token)
//        }

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

extension SwiftSyntaxParser {
    func renderNodes(_ fileUrl: URL) -> SourceInfo {
        guard let sourceFileSyntax = loadSourceUrl(fileUrl)
            else { return SourceInfo() }
        resultInfo = SourceInfo()

        let rootSyntax = visit(sourceFileSyntax)
        print("Rendering \(fileUrl)})")

        let codeSheet = CodeSheet()
        codeSheet.lastLine.position =
            codeSheet.lastLine.position.translated(dZ: nextZ - 100)

        for token in rootSyntax.tokens {
            iterateTrivia(token.leadingTrivia, token, codeSheet)
            arrange(token.text, token, codeSheet)
            iterateTrivia(token.trailingTrivia, token, codeSheet)
        }

        sceneTransaction {
            for line in codeSheet.allLines {
                MainSceneController.global.sceneState
                    .rootGeometryNode.addChildNode(line)
            }
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
    var allLines = [SCNNode]()
    var iteratorY = WordPositionIterator()
    var lastLine: SCNNode
    init() {
        lastLine = SCNNode()
        lastLine.position = SCNVector3(-25, iteratorY.nextLineY(), -25)
    }

    func newlines(_ count: Int) {
        for _ in 0..<count {
            setNewLine()
        }
    }

    private func setNewLine() {
        let newLine = SCNNode()
        newLine.position = lastLine.position.translated(
            dY: -iteratorY.linesPerBlock
        )
        allLines.append(newLine)
        lastLine = newLine
    }
}
