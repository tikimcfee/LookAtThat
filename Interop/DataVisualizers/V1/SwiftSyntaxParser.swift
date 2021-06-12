import Foundation
import SceneKit
import SwiftSyntax

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

    // MARK: - DRAW EVERYTHING
//    override func visitPost(_ node: Syntax) {
//        super.visitPost(node)
//        guard !node.children.isEmpty,
//              organizedInfo[node] == nil else {
//            return
//        }
//        let newSheet = makeSheet(
//            from: node,
//            semantics: defaultSemanticInfo(for: node)
//        )
//        organizedInfo[node] = newSheet
//    }

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

    //MARK: - Tricky CodeBlockItemSyntax
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

    override func visit(_ node: IfConfigDeclSyntax) -> DeclSyntax {
        let syntax = super.visit(node)
        let newSheet = makeSheet(
            from: node,
            semantics: SemanticInfo(
                syntaxId: node.id,
                referenceName: "#if",
                syntaxTypeName: String(describing: node.syntaxNodeType)
            )
        )
        organizedInfo[syntax] = newSheet
        return syntax
    }

    override func visit(_ node: IfConfigClauseListSyntax) -> Syntax {
        let syntax = super.visit(node)
        let newSheet = makeSheet(
            from: node,
            semantics: defaultSemanticInfo(for: node)
        )
        organizedInfo[syntax] = newSheet
        return syntax
    }

    override func visit(_ node: IfConfigClauseSyntax) -> Syntax {
        let syntax = super.visit(node)
        let newSheet = makeSheet(
            from: node.elements,
            semantics: defaultSemanticInfo(for: node.elements)
        )
        organizedInfo[syntax] = newSheet
        organizedInfo[node.elements] = newSheet
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

//    override func visit(_ node: MemberDeclListSyntax) -> Syntax {
//        let syntax = super.visit(node)
//        let newSheet = makeSheet(
//            from: node,
//            semantics: defaultSemanticInfo(for: node)
//        )
//        organizedInfo[syntax] = newSheet
//        return syntax
//    }

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

    // MARK: - Expressions

//    override func visit(_ node: FunctionCallExprSyntax) -> ExprSyntax {
//        let syntax = super.visit(node)
//        let newSheet = makeSheet(
//            from: node,
//            semantics: defaultSemanticInfo(for: node)
//        )
//        organizedInfo[syntax] = newSheet
//        return syntax
//    }
}

// I want to find all the functions
// I want to find all the functions that take strings
// I want to find all the functions that take strings and return strings

struct SemanticInfo: Hashable {
    let syntaxId: SyntaxIdentifier

    // Refer to this semantic info by this name; it's displayable
    let referenceName: String
    let syntaxTypeName: String
}
