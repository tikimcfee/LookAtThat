import Foundation
import SwiftSyntax

typealias InfoCollection = [SyntaxIdentifier: CodeSheet]

public class OrganizedSourceInfo {
    var allSheets = InfoCollection()
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

    static func + (left: OrganizedSourceInfo, right: OrganizedSourceInfo) -> OrganizedSourceInfo {
        left.allSheets.merge(right.allSheets) { left, right in
            print("Duplicated 'allSheets' key -> \(left.id), \(right.id)")
            return left
        }

        left.structs.merge(right.structs) { left, right in
            print("Duplicated 'structs' key -> \(left.id), \(right.id)")
            return left
        }

        left.classes.merge(right.classes) { left, right in
            print("Duplicated 'classes' key -> \(left.id), \(right.id)")
            return left
        }

        left.enumerations.merge(right.enumerations) { left, right in
            print("Duplicated 'enumerations' key -> \(left.id), \(right.id)")
            return left
        }

        left.functions.merge(right.functions) { left, right in
            print("Duplicated 'functions' key -> \(left.id), \(right.id)")
            return left
        }

        left.variables.merge(right.variables) { left, right in
            print("Duplicated 'variables' key -> \(left.id), \(right.id)")
            return left
        }

        left.typeAliases.merge(right.typeAliases) { left, right in
            print("Duplicated 'typeAliases' key -> \(left.id), \(right.id)")
            return left
        }

        left.protocols.merge(right.protocols) { left, right in
            print("Duplicated 'protocols' key -> \(left.id), \(right.id)")
            return left
        }

        left.initializers.merge(right.initializers) { left, right in
            print("Duplicated 'initializers' key -> \(left.id), \(right.id)")
            return left
        }

        left.deinitializers.merge(right.deinitializers) { left, right in
            print("Duplicated 'deinitializers' key -> \(left.id), \(right.id)")
            return left
        }

        left.extensions.merge(right.extensions) { left, right in
            print("Duplicated 'extensions' key -> \(left.id), \(right.id)")
            return left
        }

        return left
    }
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

    subscript(_ syntax: ExprSyntaxProtocol) -> CodeSheet? {
        get { allSheets[syntax.id] }
        set {
            let hash = syntax.id
            allSheets[hash] = newValue
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
