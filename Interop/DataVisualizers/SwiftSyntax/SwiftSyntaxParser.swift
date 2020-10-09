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
        get { allSheets[syntax.id.hashValue] }
        set {
            let hash = syntax.id.hashValue
            allSheets[hash] = newValue
        }
    }

    subscript(_ syntax: DeclSyntaxProtocol) -> CodeSheet? {
        get { allSheets[syntax.id.hashValue] }
        set {
            let hash = syntax.id.hashValue
            allSheets[hash] = newValue
            groupedBlocks(for: syntax) {
                $0[hash] = newValue
            }
        }
    }

    func groupedBlocks(for syntax: DeclSyntaxProtocol,
                       _ action: (inout InfoCollection) -> Void) {
        switch syntax {
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
}

// MARK: - Node visiting
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

    private subscript(_ index: Int) -> CodeSheet? {
        return organizedInfo.allSheets[index]
    }

    private func sheet(for type: SyntaxProtocol.Type) -> CodeSheet {
        let newSheet = CodeSheet()
        newSheet.backgroundGeometry.firstMaterial?.diffuse.contents
            = typeColor(for: type)
        return newSheet
    }

    // MARK: - Blocks

    override func visit(_ node: CodeBlockItemListSyntax) -> Syntax {
        let syntax = super.visit(node)
        let newSheet = makeSheet(from: node)
        organizedInfo[syntax] = newSheet
        return syntax
    }

    override func visit(_ node: CodeBlockItemSyntax) -> Syntax {
        let syntax = super.visit(node)
        let newSheet = makeSheet(from: node)
        organizedInfo[syntax] = newSheet
        return syntax
    }

    override func visit(_ node: MemberDeclListItemSyntax) -> Syntax {
        let syntax = super.visit(node)
        let newSheet = makeSheet(from: node)
        organizedInfo[syntax] = newSheet
        return syntax
    }

    override func visit(_ node: MemberDeclListSyntax) -> Syntax {
        let syntax = super.visit(node)
        let newSheet = makeSheet(from: node)
        organizedInfo[syntax] = newSheet
        return syntax
    }

    override func visit(_ node: CodeBlockSyntax) -> Syntax {
        let syntax = super.visit(node)
        let newSheet = makeSheet(from: node)
        organizedInfo[syntax] = newSheet
        return syntax
    }

    override func visit(_ node: MemberDeclBlockSyntax) -> Syntax {
        let syntax = super.visit(node)
        let newSheet = makeSheet(from: node)
        organizedInfo[syntax] = newSheet
        return syntax
    }

    // MARK: - Declarations

    override func visit(_ node: ClassDeclSyntax) -> DeclSyntax {
        let syntax = super.visit(node)
        let newSheet = makeSheet(from: node)
        organizedInfo[syntax] = newSheet
        return syntax
    }

    override func visit(_ node: EnumDeclSyntax) -> DeclSyntax {
        let syntax = super.visit(node)
        let newSheet = makeSheet(from: node)
        organizedInfo[syntax] = newSheet
        return syntax
    }

    override func visit(_ node: DeinitializerDeclSyntax) -> DeclSyntax {
        let syntax = super.visit(node)
        let newSheet = makeSheet(from: node)
        organizedInfo[syntax] = newSheet
        return syntax
    }

    override func visit(_ node: ExtensionDeclSyntax) -> DeclSyntax {
        let syntax = super.visit(node)
        let newSheet = makeSheet(from: node)
        organizedInfo[syntax] = newSheet
        return syntax
    }

    override func visit(_ node: FunctionDeclSyntax) -> DeclSyntax {
        let syntax = super.visit(node)
        let newSheet = makeSheet(from: node)
        organizedInfo[syntax] = newSheet
        return syntax
    }

    override func visit(_ node: ImportDeclSyntax) -> DeclSyntax {
        let syntax = super.visit(node)
        let newSheet = makeSheet(from: node)
        organizedInfo[syntax] = newSheet
        return syntax
    }

    override func visit(_ node: InitializerDeclSyntax) -> DeclSyntax {
        let syntax = super.visit(node)
        let newSheet = makeSheet(from: node)
        organizedInfo[syntax] = newSheet
        return syntax
    }

    override func visit(_ node: ProtocolDeclSyntax) -> DeclSyntax {
        let syntax = super.visit(node)
        let newSheet = makeSheet(from: node)
        organizedInfo[syntax] = newSheet
        return syntax
    }

    override func visit(_ node: StructDeclSyntax) -> DeclSyntax {
        let syntax = super.visit(node)
        let newSheet = makeSheet(from: node)
        organizedInfo[syntax] = newSheet
        return syntax
    }

    override func visit(_ node: SubscriptDeclSyntax) -> DeclSyntax {
        let syntax = super.visit(node)
        let newSheet = makeSheet(from: node)
        organizedInfo[syntax] = newSheet
        return syntax
    }

    override func visit(_ node: TypealiasDeclSyntax) -> DeclSyntax {
        let syntax = super.visit(node)
        let newSheet = makeSheet(from: node)
        organizedInfo[syntax] = newSheet
        return syntax
    }

    override func visit(_ node: VariableDeclSyntax) -> DeclSyntax {
        let syntax = super.visit(node)
        let newSheet = makeSheet(from: node)
        organizedInfo[syntax] = newSheet
        return syntax
    }
}

// MARK: - Sheet building
extension SwiftSyntaxParser {
    func makeSheet(from node: SyntaxProtocol) -> CodeSheet {
        let newSheet = sheet(for: node.syntaxNodeType)

        for nodeChildSyntax in node.children {
            if let existingSheet = self[nodeChildSyntax.id.hashValue] {
                if let declBlock = nodeChildSyntax.as(MemberDeclBlockSyntax.self) {
                    add(declBlock, to:  newSheet)
                } else if let block = nodeChildSyntax.as(CodeBlockSyntax.self) {
                    add(block, to:  newSheet)
                } else {
                    newSheet.appendChild(existingSheet)
                }
            } else {
                for token in nodeChildSyntax.tokens {
                    newSheet.add(token, textNodeBuilder)
                }
            }
        }

        newSheet.sizePageToContainerNode()
        return newSheet
    }

    func add(_ declBlock: MemberDeclBlockSyntax, to parent: CodeSheet){
        parent.add(declBlock.leftBrace, textNodeBuilder)
        for statement in declBlock.members {
            if let childSheet = self[statement.id.hashValue] {
                parent.appendChild(childSheet)
            }
        }
        parent.add(declBlock.rightBrace, textNodeBuilder)
    }

    func add(_ block: CodeBlockSyntax, to parent: CodeSheet) {
        parent.add(block.leftBrace, textNodeBuilder)
        for statement in block.statements {
            if let childSheet = self[statement.id.hashValue] {
                parent.appendChild(childSheet)
            }
        }
        parent.add(block.rightBrace, textNodeBuilder)
    }
}
#endif

