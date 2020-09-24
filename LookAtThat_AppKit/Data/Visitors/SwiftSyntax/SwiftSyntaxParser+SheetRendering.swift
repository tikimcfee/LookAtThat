import Foundation
import SceneKit
import SwiftSyntax

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
