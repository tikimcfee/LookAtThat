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

extension SyntaxChildren {
    func listOfChildren() -> String {
        reduce(into: "") { result, element in
            let elementList = element.children.listOfChildren()
            result.append(
                String(describing: element.syntaxNodeType)
            )
            result.append(
                "\n\t\t\(elementList)"
            )
            if element != last { result.append("\n\t") }
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
    var organizedInfo = OrganizedSourceInfo()
    var allRootContainerNodes = [SCNNode: CodeSheet]()

    init(wordNodeBuilder: WordNodeBuilder) {
        self.textNodeBuilder = wordNodeBuilder
        super.init()
    }

    func defaultSemanticInfo(for node: SyntaxProtocol) -> SemanticInfo {
        return SemanticInfo(
            syntaxId: node.id,
            referenceName: String(describing: node.syntaxNodeType),
            syntaxTypeName: String(describing: node.syntaxNodeType)
        )
    }

    // MARK: - Blocks
    override func visit(_ node: CodeBlockSyntax) -> Syntax {
        let syntax = super.visit(node)
        let newSheet = makeSheet(
            from: node,
            semantics: defaultSemanticInfo(for: node)
        )
        organizedInfo[syntax] = newSheet
        return syntax
    }

    override func visit(_ node: CodeBlockItemListSyntax) -> Syntax {
        let syntax = super.visit(node)
        let newSheet = makeSheet(
            from: node,
            semantics: defaultSemanticInfo(for: node)
        )
        organizedInfo[syntax] = newSheet
        return syntax
    }

    override func visit(_ node: CodeBlockItemSyntax) -> Syntax {
        let syntax = super.visit(node)
        // When we come across a block, want the one item it creates.
        // Rather than look for it in makeSheet, we pass the item itself
        // and then set *this* node as pointing to its child's one sheet.
        let newSheet = makeSheet(
            from: node.item,
            semantics: SemanticInfo(
                syntaxId: node.id,
                referenceName: String(describing: node.item.syntaxNodeType),
                syntaxTypeName: String(describing: node.item.syntaxNodeType)
            )
        )
        // Both the BlockItem and the Item itself are represented
        // by the above new sheet.
        organizedInfo[syntax] = newSheet
        organizedInfo[node.item] = newSheet

        return syntax
    }

    override func visit(_ node: MemberDeclBlockSyntax) -> Syntax {
        let syntax = super.visit(node)
        let newSheet = makeSheet(
            from: node,
            semantics: defaultSemanticInfo(for: node)
        )
        organizedInfo[syntax] = newSheet
        return syntax
    }

    override func visit(_ node: MemberDeclListSyntax) -> Syntax {
        let syntax = super.visit(node)
        let newSheet = makeSheet(
            from: node,
            semantics: defaultSemanticInfo(for: node)
        )
        organizedInfo[syntax] = newSheet
        return syntax
    }

    override func visit(_ node: MemberDeclListItemSyntax) -> Syntax {
        let syntax = super.visit(node)
        let newSheet = makeSheet(
            from: node,
            semantics: defaultSemanticInfo(for: node)
        )
        organizedInfo[syntax] = newSheet
        return syntax
    }

    // MARK: - Declarations

    override func visit(_ node: ClassDeclSyntax) -> DeclSyntax {
        let syntax = super.visit(node)
        let newSheet = makeSheet(
            from: node,
            semantics: SemanticInfo(
                syntaxId: node.id,
                referenceName: node.identifier.text,
                syntaxTypeName: String(describing: node.syntaxNodeType)
            )
        )
        organizedInfo[syntax] = newSheet
        return syntax
    }

    override func visit(_ node: EnumDeclSyntax) -> DeclSyntax {
        let syntax = super.visit(node)
        let newSheet = makeSheet(
            from: node,
            semantics: SemanticInfo(
                syntaxId: node.id,
                referenceName: node.identifier.text,
                syntaxTypeName: String(describing: node.syntaxNodeType)
            )
        )
        organizedInfo[syntax] = newSheet
        return syntax
    }

    override func visit(_ node: DeinitializerDeclSyntax) -> DeclSyntax {
        let syntax = super.visit(node)
        let newSheet = makeSheet(
            from: node,
            semantics: defaultSemanticInfo(for: node)
        )
        organizedInfo[syntax] = newSheet
        return syntax
    }

    override func visit(_ node: ExtensionDeclSyntax) -> DeclSyntax {
        let syntax = super.visit(node)
        let newSheet = makeSheet(
            from: node,
            semantics: SemanticInfo(
                syntaxId: node.id,
                referenceName: node.extendedType.description,
                syntaxTypeName: String(describing: node.syntaxNodeType)
            )
        )
        organizedInfo[syntax] = newSheet
        return syntax
    }

    override func visit(_ node: FunctionDeclSyntax) -> DeclSyntax {
        let syntax = super.visit(node)
        let newSheet = makeSheet(
            from: node,
            semantics: SemanticInfo(
                syntaxId: node.id,
                referenceName: node.identifier.text,
                syntaxTypeName: String(describing: node.syntaxNodeType)
            )
        )
        organizedInfo[syntax] = newSheet
        return syntax
    }

    override func visit(_ node: ImportDeclSyntax) -> DeclSyntax {
        let syntax = super.visit(node)
        let newSheet = makeSheet(
            from: node,
            semantics: SemanticInfo(
                syntaxId: node.id,
                referenceName: node.path.description,
                syntaxTypeName: String(describing: node.syntaxNodeType)
            )
        )
        organizedInfo[syntax] = newSheet
        return syntax
    }

    override func visit(_ node: InitializerDeclSyntax) -> DeclSyntax {
        let syntax = super.visit(node)
        let newSheet = makeSheet(
            from: node,
            semantics: defaultSemanticInfo(for: node)
        )
        organizedInfo[syntax] = newSheet
        return syntax
    }

    override func visit(_ node: ProtocolDeclSyntax) -> DeclSyntax {
        let syntax = super.visit(node)
        let newSheet = makeSheet(
            from: node,
            semantics: SemanticInfo(
                syntaxId: node.id,
                referenceName: node.identifier.text,
                syntaxTypeName: String(describing: node.syntaxNodeType)
            )
        )
        organizedInfo[syntax] = newSheet
        return syntax
    }

    override func visit(_ node: StructDeclSyntax) -> DeclSyntax {
        let syntax = super.visit(node)
        let newSheet = makeSheet(
            from: node,
            semantics: SemanticInfo(
                syntaxId: node.id,
                referenceName: node.identifier.text,
                syntaxTypeName: String(describing: node.syntaxNodeType)
            )
        )
        organizedInfo[syntax] = newSheet
        return syntax
    }

    override func visit(_ node: SubscriptDeclSyntax) -> DeclSyntax {
        let syntax = super.visit(node)
        let newSheet = makeSheet(
            from: node,
            semantics: defaultSemanticInfo(for: node)
        )
        organizedInfo[syntax] = newSheet
        return syntax
    }

    override func visit(_ node: TypealiasDeclSyntax) -> DeclSyntax {
        let syntax = super.visit(node)
        let newSheet = makeSheet(
            from: node,
            semantics: defaultSemanticInfo(for: node)
        )
        organizedInfo[syntax] = newSheet
        return syntax
    }

    override func visit(_ node: VariableDeclSyntax) -> DeclSyntax {
        let syntax = super.visit(node)
        let newSheet = makeSheet(
            from: node,
            semantics: SemanticInfo(
                syntaxId: node.id,
                referenceName: node.letOrVarKeyword.nextToken!.text,
                syntaxTypeName: String(describing: node.syntaxNodeType)
            )
        )
        organizedInfo[syntax] = newSheet
        return syntax
    }
}

// MARK: - Sheet building
extension SwiftSyntaxParser {

    func makeSheet(from node: SyntaxProtocol,
                   semantics: SemanticInfo? = nil) -> CodeSheet {
        let newSheet = CodeSheet()
            .backgroundColor(typeColor(for: node.syntaxNodeType))
            .semantics(semantics)

        for nodeChildSyntax in node.children {
            if let existingSheet = self[nodeChildSyntax.id] {
                if let declBlock = nodeChildSyntax.as(MemberDeclBlockSyntax.self) {
                    addMemberDeclBlock(declBlock, to: newSheet)
                }
                else if let codeBlock = nodeChildSyntax.as(CodeBlockSyntax.self) {
                    addCodeBlock(codeBlock, to: newSheet)
                }
                else if let clodeBlockItemList = nodeChildSyntax.as(CodeBlockItemListSyntax.self) {
                    addCodeBlockItemList(clodeBlockItemList, to: newSheet)
                }
                else {
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

    func addMemberDeclBlock(_ block: MemberDeclBlockSyntax, to parent: CodeSheet) {
        parent.add(block.leftBrace, textNodeBuilder)
        for listItem in block.members {
            if let childSheet = self[listItem.decl.id] {
                parent.appendChild(childSheet)
            }
        }
        parent.add(block.rightBrace, textNodeBuilder)
    }

    func addCodeBlock(_ block: CodeBlockSyntax, to parent: CodeSheet) {
        parent.add(block.leftBrace, textNodeBuilder)
        for statement in block.statements {
            if let childSheet = self[statement.id] {
                parent.appendChild(childSheet)
            }
        }
        parent.add(block.rightBrace, textNodeBuilder)
    }

    func addCodeBlockItemList(_ list: CodeBlockItemListSyntax, to parent: CodeSheet) {
        for blockItemChild in list {
            if let childSheet = self[blockItemChild.id] {
                parent.appendChild(childSheet)
            }
        }
    }

    private subscript(_ index: SyntaxIdentifier) -> CodeSheet? {
        return organizedInfo.allSheets[index]
    }
}
#endif

// I want to find all the functions
// I want to find all the functions that take strings
// I want to find all the functions that take strings and return strings

struct SemanticInfo: Hashable {
    let syntaxId: SyntaxIdentifier

    // Refer to this semantic info by this name; it's displayable
    let referenceName: String
    let syntaxTypeName: String
}
