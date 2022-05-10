import SwiftSyntax
//import Parser

extension SyntaxIdentifier {
    var stringIdentifier: String { "\(hashValue)" }
}

extension SwiftSyntax.TriviaPiece {
    var stringify: String {
        var output = ""
        write(to: &output)
        return output
    }
}

extension Trivia {
    var stringified: String {
		// #^ check if write(to:) appends or overwrites to avoid this map and join
        return reduce(into: "") { $1.write(to: &$0) }
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
    
    func cornerText(_ count: Int) -> String {
//        let stripped = description
//        return String(stripped.prefix(count) + stripped.suffix(count))
        
        return String(description.prefix(count))
        
//        return tokens.prefix(count).reduce(into: "") { result, token in
//            result.append(token.text)
//        }
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
