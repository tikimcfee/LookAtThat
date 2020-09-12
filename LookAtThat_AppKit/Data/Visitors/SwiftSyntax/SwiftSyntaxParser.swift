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
    var resultInfo = SourceInfo()
    var allLines = [SCNNode]()
    var iteratorY: WordPositionIterator
    var textNodeBuilder: WordNodeBuilder

    lazy var sourceInfo = SourceInfo()
    lazy var allTokens = [TokenSyntax]()

    lazy var positionSortedTokens =
        allTokens.sorted{ $0.position.utf8Offset < $1.position.utf8Offset }

    init(iterator: WordPositionIterator,
         wordNodeBuilder: WordNodeBuilder) {
        self.iteratorY = iterator
        self.textNodeBuilder = wordNodeBuilder
        super.init()
        newlines(1)
    }

    override func visit(_ node: FunctionDeclSyntax) -> DeclSyntax {
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

//        defer { iteratorY.reset() }
//        let functionBlockRoot = SCNNode()



        return super.visit(node)
    }

    override func visit(_ token: TokenSyntax) -> Syntax {
        allTokens.append(token)
        return super.visit(token)
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

        let rootSyntax = visit(sourceFileSyntax)
        print("Rendering \(rootSyntax.id)")

        for token in allTokens {
            iterateTrivia(token.leadingTrivia, token)
            arrange(token.text, token)
            iterateTrivia(token.trailingTrivia, token)
        }

        sceneTransaction {
            for line in allLines {
                MainSceneController.global.sceneState
                    .rootGeometryNode.addChildNode(line)
            }
        }

        return resultInfo
    }

    private func arrange(_ text: String, _ token: TokenSyntax) {
        let newNode = textNodeBuilder.node(for: text)
        newNode.name = token.registeredName(in: &resultInfo)
        [newNode].arrangeInLine(on: allLines.last!)
    }

    private func iterateTrivia(_ trivia: Trivia, _ token: TokenSyntax) {
        for triviaPiece in trivia {
            if case TriviaPiece.newlines(let count) = triviaPiece {
                newlines(count)
            } else {
                arrange(triviaPiece.stringify, token)
            }
        }
    }

    private func newlines(_ count: Int) {
        return (0..<count).map { _ in
            let newLine = SCNNode()
            newLine.position = iteratorY.nextPosition()
            allLines.append(newLine)
        }.last ?? {
            print("Requested new lines of count \(count)!!")
        }()
    }
}
