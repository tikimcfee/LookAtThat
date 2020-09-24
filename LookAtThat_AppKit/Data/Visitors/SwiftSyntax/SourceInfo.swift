import Foundation
import SwiftSyntax

public class SourceInfo {
    var tokenTypes = [String]()

    var identifiers = Set<String>()
    var strings = Set<String>()
    var numbers = Set<String>()

    var functions = AutoListValueDict<String, FunctionDeclSyntax>()
    var enums = AutoListValueDict<String, EnumDeclSyntax>()
    var closures = AutoListValueDict<String, ClosureExprSyntax>()
    var extensions = AutoListValueDict<String, ExtensionDeclSyntax>()
    var structs = AutoListValueDict<String, StructDeclSyntax>()

    var allTokens = AutoListValueDict<String, String>()
    var sortedTokens: [(String, [String])] {
        return allTokens.map.sorted { leftPair, rightPair in
            return leftPair.key <= rightPair.key
        }
    }
}
