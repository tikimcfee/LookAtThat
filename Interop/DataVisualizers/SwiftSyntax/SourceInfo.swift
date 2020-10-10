import Foundation
import SwiftSyntax

typealias SourceInfo = OrganizedSourceInfo

typealias SourceGroups = [Int: CodeSheet]
typealias InfoCollection = [SyntaxIdentifier: CodeSheet]

public class OrganizedSourceInfo {
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

    var allSheets = InfoCollection()
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
