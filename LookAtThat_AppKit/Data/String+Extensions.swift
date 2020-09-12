import Foundation

let searchExpression: NSRegularExpression? = {
    let whitespacePattern = #"(\s*)(\S*)(\s*)"#
    return try? NSRegularExpression(pattern: whitespacePattern, options: [])
}()

func whitespaces(in line: String) -> [Match] {
    let testRange = NSRange(line.startIndex..<line.endIndex, in: line)
    var matches = [Match]()
    searchExpression?.enumerateMatches(in: line, options: [], range: testRange) { (nextMatch, _, stop) in
        guard let someMatch = nextMatch else { return }
        guard let leading = Range(someMatch.range(at: 1), in: line),
              let text = Range(someMatch.range(at: 2), in: line),
              let trailing = Range(someMatch.range(at: 3), in: line) else { return }
        matches.append(
            Match(
                source: line,
                leading: line[leading],
                text: line[text],
                trailing: line[trailing]
            )
        )
    }
    return matches
}

extension String {
    var whitespaceMatches: [Match] { whitespaces(in: self) }
    var splitToWordsAndSpaces: [String] {
        return whitespaceMatches.reduce(into: [String]()) { result, match in
            match.store(in: &result)
        }
    }
}

extension Substring {
    var whitespaceMatches: [Match] { whitespaces(in: String(self)) }
    var splitToWordsAndSpaces: [String] {
        return whitespaceMatches.reduce(into: [String]()) { result, match in
            match.store(in: &result)
        }
    }
}

class Match: CustomStringConvertible {
    var source: String
    let leading: Substring
    let text: Substring
    let trailing: Substring

    var chunks: [Substring] { [leading, text, trailing] }

    init(source: String,
         leading: Substring,
         text: Substring,
         trailing: Substring) {
        self.source = source
        self.leading = leading
        self.text = text
        self.trailing = trailing
    }

    func store(in list: inout [String]) {
        if leading.count > 0 { list.append(String(leading)) }
        if text.count > 0 { list.append(String(text)) }
        if trailing.count > 0 { list.append(String(trailing)) }
    }

    var description: String {
        return
"""
m-----
    \(String(leading))
    \(String(text))
    \(String(trailing))
"""
    }
}
