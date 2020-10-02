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

        let parentCodeSheet = makeRootCodeSheet()

        sceneTransaction {
            sceneState.rootGeometryNode.addChildNode(parentCodeSheet.containerNode)
        }
    }

    func testInfoRender(in sceneState: SceneState) {
        let rootSheet = CodeSheet()
        rootSheet.containerNode.position =
            rootSheet.containerNode.position.translated(dZ: -100)

//        var extensionSheets = organizedInfo.extensions
//        var structSheets = organizedInfo.structs
        var classSheets = organizedInfo.classes

        [classSheets]
            .forEach {
                var iterator = $0.makeIterator()
                while let sheet = iterator.next() {
                    rootSheet.children.append(sheet.value)
                    rootSheet.containerNode.addChildNode(sheet.value.containerNode)

                    sheet.value.containerNode.position =
                        sheet.value.containerNode.position.translated(dZ: 5.0)
                }
            }

//        rootSheet.layoutChildren()
        rootSheet.sizePageToContainerNode()


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
            let parentCodeSheet = makeRootCodeSheet()
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

    func makeRootCodeSheet() -> CodeSheet {
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
                        childSheet.add(token, textNodeBuilder)
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
extension SwiftSyntaxParser {

}

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
