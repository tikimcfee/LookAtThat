import Foundation
import SceneKit
import SwiftSyntax

struct ParsingState {
    var sheet: CodeSheet = CodeSheet()
    
    var sourceFile: URL
    var sourceFileSyntax: SourceFileSyntax
    
    init(sourceFile: URL, sourceFileSyntax: SourceFileSyntax) {
        self.sourceFile = sourceFile
        self.sourceFileSyntax = sourceFileSyntax
    }
}

class CodeSheetParser: SyntaxRewriter {
    let textNodeBuilder: WordNodeBuilder
    var parseContainer: ParsingState?
    
    var organizedInfo = OrganizedSourceInfo()
    var allRootContainerNodes = [SCNNode: CodeSheet]()
    
    init(wordNodeBuilder: WordNodeBuilder) {
        self.textNodeBuilder = wordNodeBuilder
        super.init()
    }
    
    override func visitPre(_ node: Syntax) {
        
    }
    
    override func visit(_ token: TokenSyntax) -> Syntax {
        parseContainer?.sheet.add(token, textNodeBuilder)
        
        return token._syntaxNode
    }
    
    override func visitPost(_ node: Syntax) {
        
    }

}

// MARK: Setup
extension CodeSheetParser {
    func parseFile(_ url: URL) -> CodeSheet? {
        do {
            let parseContainer = try parseSyntax(source: url)
            self.parseContainer = parseContainer
            _ = visit(parseContainer.sourceFileSyntax)
            allRootContainerNodes[parseContainer.sheet.containerNode] = parseContainer.sheet
            return parseContainer.sheet
                .categoryMask(.rootCodeSheet)
                .sizePageToContainerNode()
                .removingWhitespace()
        } catch {
            print(error)
            return nil
        }
    }
    
    private func parseSyntax(source fileUrl: URL) throws -> ParsingState {
        SCNNode.BoundsCaching.Clear()
        let syntax = try SyntaxParser.parse(fileUrl)
        return ParsingState(
            sourceFile: fileUrl,
            sourceFileSyntax: syntax
        )
    }
}
