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

}
