import Foundation

let searchExpression: NSRegularExpression? = {
    let whitespacePattern = #"(\s*)(\S*)(\s*)"#
    return try? NSRegularExpression(pattern: whitespacePattern, options: [])
}()

func whitespaces(in line: String) -> [Match] {
    let testRange = NSRange(line.startIndex..<line.endIndex, in: line)
    var matches = [Match]()
    searchExpression?.enumerateMatches(in: line, options: [], range: testRange) { (nextMatch, _, stop) in
        guard let someMatch = nextMatch,
              let leading = Range(someMatch.range(at: 1), in: line),
              let text = Range(someMatch.range(at: 2), in: line),
              let trailing = Range(someMatch.range(at: 3), in: line)
        else { return }
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

public extension String {
    var stringLines: [String] {
        substringLines.map { String($0) }
    }
    var substringLines: [Substring] {
        split(omittingEmptySubsequences: false, whereSeparator: { $0.isNewline } )
    }

    internal var whitespaceMatches: [Match] { whitespaces(in: self) }
    var splitToWordsAndSpaces: [String] {
        return whitespaceMatches.reduce(into: [String]()) { result, match in
            match.store(in: &result)
        }
    }
    var splitToWords: [String] {
        return whitespaceMatches.reduce(into: [String]()) { result, match in
            match.storeText(in: &result)
        }
    }
    
    var fullNSRange: NSRange {
        let computedRange = range(of: self)!
        return NSRange(computedRange, in: self)
    }
    
    func iterateTrieKeys(_ sliceSize: Int = 5, receiver: (String) -> Void) {
        let last = count
        for nextIndex in (0..<last) {
            let start = index(startIndex, offsetBy: nextIndex)
            let end = index(startIndex, offsetBy: min(last, nextIndex + sliceSize))
            receiver(String(self[start..<end]))
            receiver(String(self[start..<end]).lowercased())
            receiver(String(self[start..<end]).uppercased())
        }
    }
}

public extension String {
    func containsMatch(_ searchString: String, caseSensitive: Bool = false) -> Bool {
        return caseSensitive
            ? contains(searchString)
            : lowercased().contains(searchString.lowercased())
    }
    
    func fuzzyMatch(_ searchString: String, caseSensitive: Bool = false) -> Bool {
        if isEmpty || searchString.isEmpty { return false }
        
        var maybeMyIndex: String.Index? = startIndex
        var maybeSearchIndex: String.Index? = searchString.startIndex
        
        while let myIndex = maybeMyIndex,
              let searchIndex = maybeSearchIndex {
            // if you find the character, look for the next
            let (mine, theirs) = caseSensitive
                ? (String(self[myIndex]), String(searchString[searchIndex]))
                : (self[myIndex].lowercased(), searchString[searchIndex].lowercased())
            
            if mine == theirs {
                #if os(iOS)
                maybeSearchIndex = searchString.index(searchIndex, offsetBy: 1, limitedBy: searchString.endIndex)
                #else
                maybeSearchIndex = searchString.index(searchIndex, offsetBy: 1)
                #endif
                // If we've gone off the index, we've found everything - return early
                if maybeSearchIndex == nil || maybeSearchIndex == searchString.endIndex {
                    return true
                }
            }
            
            // Always advance to next character; if we go off the end, we haven't found everything
            #if os(iOS)
            maybeMyIndex = index(myIndex, offsetBy: 1, limitedBy: endIndex)
            #else
            maybeMyIndex = index(myIndex, offsetBy: 1)
            #endif
            
            if maybeMyIndex == nil || maybeMyIndex == endIndex {
                return false
            }
        }
        
        return false
    }
}

extension Substring {
    var stringLines: [String] {
        substringLines.map { String($0) }
    }
    var substringLines: [Substring] {
        split(omittingEmptySubsequences: false, whereSeparator: { $0.isNewline } )
    }

    var whitespaceMatches: [Match] { whitespaces(in: String(self)) }
    var splitToWordsAndSpaces: [String] {
        return whitespaceMatches.reduce(into: [String]()) { result, match in
            match.store(in: &result)
        }
    }
    var splitToWords: [String] {
        return whitespaceMatches.reduce(into: [String]()) { result, match in
            match.storeText(in: &result)
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
    
    func storeText(in list: inout [String]) {
        if text.count > 0 { list.append(String(text)) }
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
