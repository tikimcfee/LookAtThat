import Foundation
import SceneKit

#if os(iOS)
class SwiftSyntaxParser {
    var textNodeBuilder: WordNodeBuilder
    var resultInfo = SourceInfo()

    init(wordNodeBuilder: WordNodeBuilder) {
        self.textNodeBuilder = wordNodeBuilder
    }
}

extension SwiftSyntaxParser {
    func prepareRendering(source fileUrl: URL) {
        print("\(#function) not implemented")
    }

    func render(in sceneState: SceneState) {
        print("\(#function) not implemented")
    }

    func renderAndDuplicate(in sceneState: SceneState) {
        print("\(#function) not implemented")
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

    private func loadSourceUrl(_ url: URL) -> Any? {
        print("\(#function) not implemented")
        return nil
    }
}
#elseif os(OSX)
import SwiftSyntax

class SwiftSyntaxParser: SyntaxRewriter {
    var preparedSourceFile: URL?
    var sourceFileSyntax: SourceFileSyntax?
    var rootSyntaxNode: Syntax?
    var resultInfo = SourceInfo()

    var nodesToSheets = [SCNNode: CodeSheet]()

    var textNodeBuilder: WordNodeBuilder

    init(wordNodeBuilder: WordNodeBuilder) {
        self.textNodeBuilder = wordNodeBuilder
        super.init()
    }

    override func visit(_ node: FunctionDeclSyntax) -> DeclSyntax {
        resultInfo.functionSheets[node.identifier.text]
            .append(makeSheet(from: node))

        return super.visit(node)
    }

    override func visit(_ node: EnumDeclSyntax) -> DeclSyntax {
        resultInfo.enumSheets[node.identifier.text]
            .append(makeSheet(from: node))

        return super.visit(node)
    }

    override func visit(_ node: ExtensionDeclSyntax) -> DeclSyntax {
        resultInfo.extensionSheets[node.extendedType.firstToken!.text]
            .append(makeSheet(from: node))

        return super.visit(node)
    }

    override func visit(_ node: StructDeclSyntax) -> DeclSyntax {
        resultInfo.structSheets[node.identifier.text]
            .append(makeSheet(from: node))

        return super.visit(node)
    }

    private func makeSheet(from node: SyntaxProtocol) -> CodeSheet {
        let newSheet = CodeSheet()

        newSheet.pageGeometry.firstMaterial?.diffuse.contents
            = typeColor(for: node.syntaxNodeType)

        node.tokens.forEach{ add($0, to: newSheet)}
        return newSheet
    }
}

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

//        let rootSheet = CodeSheet()
//
//        var functionSheets = resultInfo.functionSheets.map.values.makeIterator()
//        var enumSheets = resultInfo.enumSheets.map.values.makeIterator()
//        var extensionSheets = resultInfo.extensionSheets.map.values.makeIterator()
//        var structSheets = resultInfo.structSheets.map.values.makeIterator()
//
//        while let sheets = functionSheets.next()
//                ?? enumSheets.next()
//                ?? extensionSheets.next()
//                ?? structSheets.next() {
//            rootSheet.children.append(contentsOf: sheets)
//            sheets.forEach { resultSheet in
//                resultSheet.containerNode.position =
//                    resultSheet.containerNode.position.translated(dZ: 5.0)
//
//                rootSheet.containerNode.addChildNode(resultSheet.containerNode)
//                resultSheet.sizePageToContainerNode()
//                resultSheet.containerNode.position.x +=
//                    resultSheet.containerNode.lengthX.vector / 2.0
//                resultSheet.containerNode.position.y -=
//                    resultSheet.containerNode.lengthY.vector / 2.0
//            }
//        }
//        rootSheet.layoutChildren()
//        rootSheet.sizePageToContainerNode()

        sceneTransaction {
            sceneState.rootGeometryNode.addChildNode(parentCodeSheet.containerNode)
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
