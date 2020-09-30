import Foundation
import SceneKit
import SwiftSyntax

extension SwiftSyntaxParser {

    func makeCodeSheet() -> CodeSheet {
        let parentCodeSheet = CodeSheet()

        parentCodeSheet.containerNode.position =
            parentCodeSheet.containerNode.position
                .translated(dY: -00.0, dZ: nextZ - 50)

        for node in rootSyntaxNode!.children {
            print("At node \(node.syntaxNodeType)")
            visitChildrenOf(node, parentCodeSheet)
        }

        parentCodeSheet.layoutChildren()
        parentCodeSheet.sizePageToContainerNode()

        // Save node to be looked up later
        nodesToSheets[parentCodeSheet.containerNode] = parentCodeSheet

        return parentCodeSheet
    }

    private func visitChildrenOf(_ childSyntaxNode: SyntaxChildren.Element,
                                 _ parentCodeSheet: CodeSheet) {
//        print("Visiting '\(childSyntaxNode.syntaxNodeType)', '\(childSyntaxNode.firstToken?.tokenKind)'")

        for syntaxChild in childSyntaxNode.children {
//            print("-- Inner '\(syntaxChild.syntaxNodeType)', '\(syntaxChild.firstToken?.tokenKind)'")

            let childSheet = parentCodeSheet.spawnChild()
            childSheet.containerNode.position.z += 5

            childSheet.pageGeometry.firstMaterial?.diffuse.contents =
                backgroundColor(for: syntaxChild)

            for innerChild in syntaxChild.children {
                let type = innerChild.syntaxNodeType
                let isRecurseType =
                    type == StructDeclSyntax.self
                    || type == ClassDeclSyntax.self
                    || type == FunctionDeclSyntax.self
                    || type == EnumDeclSyntax.self
                    || type == ExtensionDeclSyntax.self
//                    || type == CodeBlockItemListSyntax.self
//                    || type == CodeBlockItemSyntax.self
                if isRecurseType {
//                    print("Found recurse, '\(innerChild.syntaxNodeType)'")
                    visitChildrenOf(syntaxChild, parentCodeSheet)
                } else {
                    for token in innerChild.tokens {
                        add(token, to: childSheet)
                    }
                }
            }

            childSheet.sizePageToContainerNode()
            childSheet.containerNode.position.x +=
                childSheet.containerNode.lengthX.vector / 2.0
            childSheet.containerNode.position.y -=
                childSheet.containerNode.lengthY.vector / 2.0
        }
    }

    func backgroundColor(for syntax: SyntaxChildren.Element) -> NSUIColor {
        let type = syntax.syntaxNodeType
        print("For color: \(type)")
        if type == StructDeclSyntax.self { return NSUIColor.systemTeal }
        if type == ClassDeclSyntax.self { return NSUIColor.systemGreen }
        if type == FunctionDeclSyntax.self { return NSUIColor.systemPink }
        if type == EnumDeclSyntax.self { return NSUIColor.systemOrange }
        if type == ExtensionDeclSyntax.self { return NSUIColor.systemBrown }
        return NSUIColor.init(deviceRed: 0.2, green: 0.2, blue: 0.4, alpha: 0.85)
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
