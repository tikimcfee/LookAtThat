import Foundation
import SwiftSyntax

public class SourceInfo {
    var tokenTypes = [String]()

    var identifiers = Set<String>()
    var strings = Set<String>()
    var numbers = Set<String>()

    var functionSheets = AutoListValueDict<String, CodeSheet>()
    var enumSheets = AutoListValueDict<String, CodeSheet>()
    var extensionSheets = AutoListValueDict<String, CodeSheet>()
    var structSheets = AutoListValueDict<String, CodeSheet>()
    var classSheets = AutoListValueDict<String, CodeSheet>()

    var allTokens = AutoListValueDict<String, String>()

    var sortedTokens: [(String, [String])] {
        return allTokens.map.sorted { leftPair, rightPair in
            return leftPair.key <= rightPair.key
        }
    }
}
