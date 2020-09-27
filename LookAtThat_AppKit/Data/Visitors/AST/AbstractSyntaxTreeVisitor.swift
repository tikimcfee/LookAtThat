import Foundation
import AST
import Parser
import Source
import SwiftSyntax

// AST Lib
class AbstractSyntaxTreeVisitor: VisitorDelegate {

    var resourceName = "WordNodeIntrospect"
    var resourceType = ""
    lazy var resourceUrl: URL? = {
        Bundle.main.url(forResource: resourceName, withExtension: resourceType)
    }()
    lazy var resourcePath = {
        Bundle.main.path(forResource: resourceName, ofType: resourceType)
    }()

    private let builder = WordNodeBuilder()

    private lazy var visitor: AbstractSyntaxTreeVisitorMuxer = {
        let visitor = AbstractSyntaxTreeVisitorMuxer(self)
        return visitor
    }()
}

extension AbstractSyntaxTreeVisitor {
    func getTopLevelDeclaration() -> TopLevelDeclaration? {
        do {
            let sourceFile = try SourceReader.read(at: resourcePath!)
            let parser = Parser(source: sourceFile)
            return try parser.parse()
        } catch {
            print(error)
            return nil
        }
    }

    func traverse(_ root: TopLevelDeclaration) {
        let didTraverse = try? visitor.traverse(root)
        print("Traversal complete: \(didTraverse?.description ?? "(failed)")")
    }

    func buildTreeList() -> SourceTreeList {
        guard let root = getTopLevelDeclaration()
            else { return [] }
        traverse(root)
        return visitor.sortedSourceLocations
    }

    func didVisit(_ node: ASTNode) {
        // do something while it's working...
    }
}
