import Foundation
import SwiftSyntax

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
    subscript(_ syntaxId: SyntaxIdentifier) -> CodeSheet? {
        get { allSheets[syntaxId] }
    }

    subscript(_ syntax: Syntax) -> CodeSheet? {
        get { allSheets[syntax.id] }
        set {
            let hash = syntax.id
            allSheets[hash] = newValue
        }
    }

    subscript(_ syntax: DeclSyntaxProtocol) -> CodeSheet? {
        get { allSheets[syntax.id] }
        set {
            let hash = syntax.id
            allSheets[hash] = newValue
            groupedBlocks(for: syntax) {
                $0[hash] = newValue
            }
        }
    }

    func groupedBlocks(for syntax: DeclSyntaxProtocol,
                       _ action: (inout InfoCollection) -> Void) {
        switch syntax.syntaxNodeType {
        case is ProtocolDeclSyntax.Type:
            action(&protocols)
        case is TypealiasDeclSyntax.Type:
            action(&typeAliases)
        case is VariableDeclSyntax.Type:
            action(&variables)
        case is ClassDeclSyntax.Type:
            action(&classes)
        case is EnumDeclSyntax.Type:
            action(&enumerations)
        case is ExtensionDeclSyntax.Type:
            action(&extensions)
        case is FunctionDeclSyntax.Type:
            action(&functions)
        case is StructDeclSyntax.Type:
            action(&structs)
        default:
            break
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
