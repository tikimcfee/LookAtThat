import Foundation
import SceneKit
import SwiftSyntax

extension CodeSheet {
        
}

extension SwiftSyntaxParser {

    func makeCodeSheet() -> CodeSheet {
        let parentCodeSheet = CodeSheet()

        parentCodeSheet.containerNode.position =
            parentCodeSheet.containerNode.position
                .translated(dY: -100.0, dZ: nextZ - 200)

        for node in rootSyntaxNode!.children {
            print("At node \(node.syntaxNodeType)")
            visitChildrenOf(node, parentCodeSheet)
        }

        parentCodeSheet.sizePageToContainerNode()

        return parentCodeSheet
    }

    private func visitChildrenOf(_ childSyntaxNode: SyntaxChildren.Element,
                                 _ parentCodeSheet: CodeSheet) {

        for syntaxChild in childSyntaxNode.children {
            let childSheet = parentCodeSheet.spawnChild()
            childSheet.pageGeometry.firstMaterial?.diffuse.contents = NSUIColor.gray
            childSheet.containerNode.position.z += 25

            for token in syntaxChild.tokens {
                add(token, to: childSheet)
            }

            childSheet.sizePageToContainerNode()
            childSheet.containerNode.position.x +=
                childSheet.containerNode.lengthX.vector / 2.0
            childSheet.containerNode.position.y -=
                childSheet.containerNode.lengthY.vector / 2.0

            parentCodeSheet.arrangeLastChild()
        }
    }
}

// CodeSheet operations
extension SwiftSyntaxParser {
    func add(_ token: TokenSyntax,
             to codeSheet: CodeSheet) {
        iterateTrivia(token.leadingTrivia, token, codeSheet)
        arrange(token.text, token, codeSheet)
        iterateTrivia(token.trailingTrivia, token, codeSheet)
    }

    func arrange(_ text: String,
                 _ token: TokenSyntax,
                 _ codeSheet: CodeSheet) {
        let newNode = textNodeBuilder.node(for: text)
        newNode.name = token.registeredName(in: &resultInfo)
        [newNode].arrangeInLine(on: codeSheet.lastLine)
    }

    func iterateTrivia(_ trivia: Trivia,
                       _ token: TokenSyntax,
                       _ codeSheet: CodeSheet) {
        for triviaPiece in trivia {
            switch triviaPiece {
            case let .newlines(count):
                codeSheet.newlines(count)
            case let .lineComment(comment),
                 let .blockComment(comment),
                 let .docLineComment(comment),
                 let .docBlockComment(comment):
                let lines = comment.split(whereSeparator: { $0.isNewline })
                for piece in lines {
                    arrange(String(piece), token, codeSheet)
                    if piece != lines.last {
                        codeSheet.newlines(1)
                    }
                }
            default:
                arrange(triviaPiece.stringify, token, codeSheet)
            }
        }
    }
}
