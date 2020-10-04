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
            result.append(token.alltext)
        }
    }
}

extension TokenSyntax {
    var typeName: String { return String(describing: tokenKind) }

    var alltext: String {
        leadingTrivia.stringified
        .appending(text)
        .appending(trailingTrivia.stringified)
    }
}
