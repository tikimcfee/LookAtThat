import Foundation
import SwiftSyntax
import SceneKit

// SwiftSyntax
class SwiftSyntaxParser: SyntaxRewriter {
    var preparedSourceFile: URL?
    var sourceFileSyntax: SourceFileSyntax?
    var rootSyntaxNode: Syntax?
    var resultInfo = SourceInfo()

    var textNodeBuilder: WordNodeBuilder

    init(wordNodeBuilder: WordNodeBuilder) {
        self.textNodeBuilder = wordNodeBuilder
        super.init()
    }

    override func visit(_ node: CodeBlockItemListSyntax) -> Syntax {
//        for codeBlock in node.children {
//            print("----------- Code block -----------")
//            let thisBlock = codeBlock.tokens.reduce(into: "") {
//                $0.append($1.alltext)
//            }
//            print(thisBlock)
//        }
        return super.visit(node)
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

        let parentCodeSheet = makeCodeSheet()

        sceneTransaction {
            sceneState.rootGeometryNode.addChildNode(parentCodeSheet.containerNode)
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
