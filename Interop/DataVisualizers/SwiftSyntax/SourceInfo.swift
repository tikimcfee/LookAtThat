import Foundation

public class SourceInfo {
    var tokenTypes = [String]()

    var identifiers = Set<String>()
    var strings = Set<String>()
    var numbers = Set<String>()

    var functionSheets = AutoListValueDict<Int, CodeSheet>()
    var enumSheets = AutoListValueDict<Int, CodeSheet>()
    var extensionSheets = AutoListValueDict<Int, CodeSheet>()
    var structSheets = AutoListValueDict<Int, CodeSheet>()
    var classSheets = AutoListValueDict<Int, CodeSheet>()

    var allSheets = [Int: CodeSheet]()

    var allTokens = AutoListValueDict<String, String>()

    var sortedTokens: [(String, [String])] {
        return allTokens.map.sorted { leftPair, rightPair in
            return leftPair.key <= rightPair.key
        }
    }
}

typealias InfoCollection = [Int: CodeSheet]
public class OrganizedSourceInfo {
    // map each syntax type of interest to a collection
    // use those collection to sift out meaningful structures
    // -- all functions; all structs; all enums
    // then, when building parents:
    /*
     for syntaxChild in self.children {
        (recursively lay children of this out)
        if existingSheet for syntaxChild.id in allSheets {
            parentSheet.children.add(existing sheet)
            ?? magical layout function ??
        }
     }
     */
    var structs = InfoCollection()
    var classes = InfoCollection()
    var enumerations = InfoCollection()
    var functions = InfoCollection()
    var variables = InfoCollection()
    var typeAliases = InfoCollection()
    var protocols = InfoCollection()
    var initializers = InfoCollection()
    var deinitializers = InfoCollection()
    var extensions = InfoCollection()

    // Probably don't need this...
    var allDeclarations = [Int: CodeSheet]()
}

extension SourceInfo {
    func dump() {
        [(functionSheets,"functions"),
         (enumSheets,"enums"),
         (extensionSheets,"extensions"),
         (structSheets,"structs"),
         (classSheets,"classes")
        ].forEach {
            var iterator = $0.0.map.makeIterator()
            while let (id, sheets) = iterator.next() {
                for sheet in sheets {
                    print("\($0.1) | \(id) --> \(sheet.id); \(sheet.allLines.count) lines")
                }
            }
        }
    }
}

extension OrganizedSourceInfo {
    func dump() {
        [(functions,"functions"),
         (enumerations,"enums"),
         (extensions,"extensions"),
         (structs,"structs"),
         (classes,"classes")
        ].forEach {
            var iterator = $0.0.makeIterator()
            while let (id, sheet) = iterator.next() {
                print("\($0.1) | \(id) --> \(sheet.id); \(sheet.allLines.count) lines, \(sheet.children.count) children")
            }
        }


    }
}
