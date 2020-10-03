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

extension OrganizedSourceInfo {
    subscript(_ syntax: Syntax) -> CodeSheet? {
        get { allDeclarations[syntax.id.hashValue] }
        set {
            let hash = syntax.id.hashValue
            allDeclarations[hash] = newValue
            groupedBlocks(for: syntax) { $0[hash] = newValue }
        }
    }

    func groupedBlocks(for syntax: Syntax, _ action: (inout InfoCollection) -> Void) {
        switch syntax.asProtocol(DeclSyntaxProtocol.self) {
        case is ClassDeclSyntax:
            action(&classes)
        case is EnumDeclSyntax:
            action(&enumerations)
        case is ExtensionDeclSyntax:
            action(&extensions)
        case is FunctionDeclSyntax:
            action(&functions)
        case is StructDeclSyntax:
            action(&structs)
        default:
            break
        }
    }

    func nodeIsRenderedAsGroup(_ syntax: Syntax) -> Bool {
        let declarationType = syntax.asProtocol(DeclSyntaxProtocol.self)
        switch declarationType {
        case is ClassDeclSyntax,
             is DeinitializerDeclSyntax,
             is EnumDeclSyntax,
             is ExtensionDeclSyntax,
             is FunctionDeclSyntax,
             is ImportDeclSyntax,
             is InitializerDeclSyntax,
             is ProtocolDeclSyntax,
             is StructDeclSyntax,
             is SubscriptDeclSyntax,
             is TypealiasDeclSyntax,
             is VariableDeclSyntax:
//            print("Render: \(String(describing: type)) as group; \n---\(syntax.allText)\n---")
            return true
        default:
            break
        }

        if syntax.as(CodeBlockItemListSyntax.self) != nil
        || syntax.as(CodeBlockItemSyntax.self) != nil
        {
            return true
        }

        if syntax.as(MemberDeclBlockSyntax.self) != nil
        || syntax.as(MemberDeclListSyntax.self) != nil
        || syntax.as(MemberDeclListItemSyntax.self) != nil
        {
            return true
        }

        return false
    }
}

class SwiftSyntaxParser: SyntaxRewriter {
    // Dependencies
    let textNodeBuilder: WordNodeBuilder

    // Source file reading results
    var preparedSourceFile: URL?
    var sourceFileSyntax: SourceFileSyntax?
    var rootSyntaxNode: Syntax?

    // One of these ideas will net me 'blocks of code' to '3d sheets'
    var resultInfo = SourceInfo()
    var organizedInfo = OrganizedSourceInfo()
    var nodesToSheets = [SCNNode: CodeSheet]()

    init(wordNodeBuilder: WordNodeBuilder) {
        self.textNodeBuilder = wordNodeBuilder
        super.init()
    }

    override func visitPost(_ node: Syntax) {
        guard organizedInfo.nodeIsRenderedAsGroup(node) else {
            // only make sheets out of high-level, readable 'groups'.
            // this will need a lot of tweaking, and could benefit from
            // external configuration
            return
        }
        
        let newSheet = makeSheet(from: node)
        organizedInfo[node] = newSheet
    }

    func makeSheet(from node: SyntaxProtocol) -> CodeSheet {
        let newSheet = CodeSheet()

        newSheet.pageGeometry.firstMaterial?.diffuse.contents
            = typeColor(for: node.syntaxNodeType)

//        print("Making sheet for '\(node.syntaxNodeType)'")
        for nodeChildSyntax in node.children {
//            print("Looking for a '\(nodeChildSyntax.syntaxNodeType)'")
            if let existingSheet = organizedInfo.allDeclarations[nodeChildSyntax.id.hashValue] {
//                print("+ Using existing sheet")
                newSheet.addChildAtLastLine(existingSheet)
            } else {
//                print("! Adding tokens")
                for token in nodeChildSyntax.tokens {
//                    print("\t--\n", "\t\(token.alltext)", "\n\t--")
                    newSheet.add(token, textNodeBuilder)
                }
            }
        }

        newSheet.sizePageToContainerNode()
        return newSheet
    }


}
#endif
