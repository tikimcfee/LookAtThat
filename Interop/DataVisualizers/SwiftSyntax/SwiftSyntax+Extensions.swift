import SwiftSyntax

extension SwiftSyntax.TriviaPiece {
    var stringify: String {
        var output = ""
        write(to: &output)
        return output
    }
}

extension Trivia {
    var stringified: String {
        return map { $0.stringify }.joined()
    }
}

extension Syntax {
    var allText: String {
        return tokens.reduce(into: "") { result, token in
            result.append(token.triviaAndText)
        }
    }
    
    var strippedText: String {
        return tokens.reduce(into: "") { result, token in
            result.append(token.text)
        }
    }
}

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

public extension TokenSyntax {
    var typeName: String { return String(describing: tokenKind) }

    var triviaAndText: String {
        leadingTrivia.stringified
        .appending(text)
        .appending(trailingTrivia.stringified)
    }

    var splitText: [String] {
        switch tokenKind {
        case let .stringSegment(literal):
            return literal.stringLines
        case let .stringLiteral(literal):
            return literal.stringLines
        default:
            return [text]
        }
    }
    
    var defaultColor: NSUIColor {
        switch tokenKind {
        case .funcKeyword:
            return .purple
        case .enumKeyword:
            return .green
        case .classKeyword:
            return .green
        case .structKeyword:
            return .brown
        case .letKeyword:
            return .orange
        case .varKeyword:
            return .red
        case .forKeyword:
            return .yellow
        default:
            return .white
        }
    }
}
