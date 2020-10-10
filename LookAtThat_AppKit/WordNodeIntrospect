import Foundation

class WordParser {

    let sliceSize = 100
    var sliceCount: Int { sortedDictionary.count / sliceSize }
    lazy var jsonDecoder = JSONDecoder()

    lazy var testDictionary = [
        "Hello" : "A simple greeting when you meet someone",
        "Goodbye" : "Said to someone you said hello to as you leave",
        "Wut" : "x a 11 22 -- ss /? ?? ;;ss; dasd"
    ]

    lazy var testSourceFileLines: [Substring] = {
        let sourceData = fileData("WordNodeIntrospect")
        guard sourceData.count > 0 else { return [] }
        let sourceText = String(data: sourceData, encoding: .utf8) ?? ""
        let sourceLines = sourceText.split(whereSeparator: { $0.isNewline })
        return sourceLines
    }()

    lazy var dictionary: [String:String] = {
        let dictionary = try? jsonDecoder.decode(
            Dictionary<String, String>.self,
            from: fileData("dict", "json")
        )
        return dictionary ?? [:]
    }()

    lazy var sortedDictionary: [(String, String)] = {
        return dictionary.sorted(by: { $0.key <= $1.key })
    }()

    typealias DefinitionSlice = ArraySlice<(String, String)>
    lazy var definitionSliceIterator: IndexingIterator<[DefinitionSlice]> = {
        return sortedDictionary.slices(sliceSize: sliceSize).makeIterator()
    }()

    func wordStream(_ handler: (String, String) -> Void) {
        dictionary
            .sorted { $0.key <= $1.key }
            .forEach{ word, definition in
                handler(word, definition)
            }
    }

}
