import Foundation

struct HistorianDefinition: Decodable {
    let definedWord: String
    let definitionString: String
}

func fileData(_ name: String, _ type: String = "") -> Data {
    return fileHandle(name, type)?.availableData ?? Data()
}

func fileHandle(_ name: String, _ type: String = "") -> FileHandle? {
    guard let filepath = Bundle.main.path(
        forResource: name, ofType: type
    ) else { return nil }

    return FileHandle(forReadingAtPath: filepath)
}

extension Array {
    func slices(sliceSize: Int) -> [ArraySlice<Element>] {
        return (0...(count / sliceSize)).reduce(into: [ArraySlice<Element>]()) { result, slicePosition in
            let sliceStart = slicePosition * sliceSize
            let sliceEnd = Swift.min(sliceStart + sliceSize, count)
            result.append(self[sliceStart..<sliceEnd])
        }
    }
}

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
