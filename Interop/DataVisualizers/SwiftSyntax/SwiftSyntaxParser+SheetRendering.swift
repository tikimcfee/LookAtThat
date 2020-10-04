import Foundation
import SceneKit
import SwiftSyntax

#if os(OSX)
// Node building
extension SwiftSyntaxParser {

    func prepareRendering(source fileUrl: URL) {
        preparedSourceFile = fileUrl
        guard let loadedFile = loadSourceUrl(fileUrl) else {
            print("Couldn't load \(fileUrl)")
            return
        }
        sourceFileSyntax = loadedFile
        rootSyntaxNode = visit(loadedFile)
    }

    func render(in sceneState: SceneState) {
        guard rootSyntaxNode != nil else {
            print("No syntax to render for \(String(describing: preparedSourceFile))")
            return
        }

        let rootSheet = makeSheetFromInfo()

        sceneTransaction {
            sceneState.rootGeometryNode.addChildNode(rootSheet.containerNode)
        }
    }

    func renderAndDuplicate(in sceneState: SceneState) {
        guard rootSyntaxNode != nil else {
            print("No syntax to render for \(String(describing: preparedSourceFile))")
            return
        }

        sceneTransaction {
            let parentCodeSheet = makeSheetFromInfo()
            let wireSheet = parentCodeSheet.wireSheet
            let backConverted = wireSheet.makeCodeSheet()
            backConverted.containerNode.position.x += 100

            sceneState.rootGeometryNode.addChildNode(parentCodeSheet.containerNode)
            sceneState.rootGeometryNode.addChildNode(backConverted.containerNode)
        }
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

    func parse(_ source: String) -> SourceFileSyntax? {
        do {
            return try SyntaxParser.parse(source: source)
        } catch {
            print("|InvalidRawSource| failed to load > \(error)")
            return nil
        }
    }

    private func loadSourceUrl(_ url: URL) -> SourceFileSyntax? {
        do {
            return try SyntaxParser.parse(url)
        } catch {
            print("|\(url)| failed to load > \(error)")
            return nil
        }
    }
}
#endif

extension SwiftSyntaxParser {

    func makeSheetFromInfo() -> CodeSheet {
        let parentCodeSheet = makeSheet(from: rootSyntaxNode!)
        parentCodeSheet.sizePageToContainerNode()

        parentCodeSheet.containerNode.position =
            parentCodeSheet.containerNode.position
                .translated(dZ: nextZ - 50)

        // Save node to be looked up later
        nodesToSheets[parentCodeSheet.containerNode] = parentCodeSheet

        return parentCodeSheet
    }

    func backgroundColor(for syntax: SyntaxChildren.Element) -> NSUIColor {
        return typeColor(for: syntax.syntaxNodeType)
    }

    func typeColor(for type: SyntaxProtocol.Type) -> NSUIColor {
        if type == StructDeclSyntax.self { return NSUIColor.systemTeal }
        if type == ClassDeclSyntax.self { return NSUIColor.systemIndigo }
        if type == FunctionDeclSyntax.self { return NSUIColor.systemPink }
        if type == EnumDeclSyntax.self { return NSUIColor.systemOrange }
        if type == ExtensionDeclSyntax.self { return NSUIColor.systemBrown }
        if type == VariableDeclSyntax.self { return NSUIColor.systemGreen }
        if type == TypealiasDeclSyntax.self { return NSUIColor.systemPurple }
        return NSUIColor.init(deviceRed: 0.2, green: 0.2, blue: 0.4, alpha: 0.95)
    }
}

// CodeSheet operations
extension CodeSheet {
    func add(_ token: TokenSyntax,
             _ builder: WordNodeBuilder) {
        iterateTrivia(token.leadingTrivia, token, builder)
        arrange(token.text, token, builder)
        iterateTrivia(token.trailingTrivia, token, builder)
    }

    func arrange(_ text: String,
                 _ token: TokenSyntax,
                 _ builder: WordNodeBuilder) {
        let newNode = builder.node(for: text)
        [newNode].arrangeInLine(on: lastLine)
    }

    func iterateTrivia(_ trivia: Trivia,
                       _ token: TokenSyntax,
                       _ builder: WordNodeBuilder) {
        for triviaPiece in trivia {
            switch triviaPiece {
            case let .newlines(count):
                newlines(count)
            case let .lineComment(comment),
                 let .blockComment(comment),
                 let .docLineComment(comment),
                 let .docBlockComment(comment):
                let lines = comment.split(whereSeparator: { $0.isNewline })
                for piece in lines {
                    arrange(String(piece), token, builder)
                    if piece != lines.last {
                        newlines(1)
                    }
                }
            default:
                arrange(triviaPiece.stringify, token, builder)
            }
        }
    }
}
