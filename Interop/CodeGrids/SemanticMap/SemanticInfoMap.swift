//
//  GridInfo.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 10/26/21.
//

import Foundation
import SwiftSyntax
import SceneKit
import MetalLink

typealias AssociatedSyntaxSet = Set<SyntaxIdentifier>
typealias AssociatedSyntaxMap = [SyntaxIdentifier: [SyntaxIdentifier: Int]]

public class SemanticInfoMap {
    
    // MARK: - Core association sets
    
    // TODO: *1 = these can be merged! SemanticInfo wraps Syntax
    // var totalProtonicReversal = [NodeId: (Syntax, SemanticInfo)]
    // Or just one can be removed.. I think I walked myself into duplicating the map
    // since SemanticInfo captures the node Syntax... TreeSitter will make me laughcry.
    var flattenedSyntax = [SyntaxIdentifier: Syntax]()  //TODO: *1
    var semanticsLookupBySyntaxId = [SyntaxIdentifier: SemanticInfo]()  //TODO: *1
    var syntaxIDLookupByNodeId = [NodeSyntaxID: SyntaxIdentifier]()

	var structs = AssociatedSyntaxMap()
	var classes = AssociatedSyntaxMap()
	var enumerations = AssociatedSyntaxMap()
	var functions = AssociatedSyntaxMap()
	var variables = AssociatedSyntaxMap()
	var typeAliases = AssociatedSyntaxMap()
	var protocols = AssociatedSyntaxMap()
	var initializers = AssociatedSyntaxMap()
	var deinitializers = AssociatedSyntaxMap()
	var extensions = AssociatedSyntaxMap()
    var switches = AssociatedSyntaxMap()
    
    var allSemanticInfo: [SemanticInfo] {
        return Array(semanticsLookupBySyntaxId.values)
    }
}

extension SemanticInfoMap {
    enum Category: String, CaseIterable, Identifiable {
        var id: String { rawValue }
        case structs = "Structs"
        case classes = "Classes"
        case enumerations = "Enumerations"
        case functions = "Functions"
        case variables = "Variables"
        case typeAliases = "Type Aliases"
        case protocols = "Protocols"
        case initializers = "Initializers"
        case deinitializers = "Deinitializers"
        case extensions = "Extensions"
        case switches = "Switches"
    }
    
    func category(
        _ category: SemanticInfoMap.Category,
        _ receiver: (inout AssociatedSyntaxMap) -> Void
    ) {
        switch category {
        case .structs: receiver(&structs)
        case .classes: receiver(&classes)
        case .enumerations: receiver(&enumerations)
        case .functions: receiver(&functions)
        case .variables: receiver(&variables)
        case .typeAliases: receiver(&typeAliases)
        case .protocols: receiver(&protocols)
        case .initializers: receiver(&initializers)
        case .deinitializers: receiver(&deinitializers)
        case .extensions: receiver(&extensions)
        case .switches: receiver(&switches)
        }
    }
    
    func map(for category: SemanticInfoMap.Category) -> AssociatedSyntaxMap {
        switch category {
        case .structs: return structs
        case .classes: return classes
        case .enumerations: return enumerations
        case .functions: return functions
        case .variables: return variables
        case .typeAliases: return typeAliases
        case .protocols: return protocols
        case .initializers: return initializers
        case .deinitializers: return deinitializers
        case .extensions: return extensions
        case .switches: return switches
        }
    }
}

// MARK: - Simplified mapping

extension SemanticInfoMap {
    func addFlattened(_ syntax: Syntax) {
        flattenedSyntax[syntax.id] = syntax
    }
    
    func insertSemanticInfo(_ id: SyntaxIdentifier, _ info: SemanticInfo) {
        semanticsLookupBySyntaxId[id] = info
    }
    
    func insertNodeInfo(_ nodeId: NodeSyntaxID, _ syntaxId: SyntaxIdentifier) {
        syntaxIDLookupByNodeId[nodeId] = syntaxId
    }
}

// MARK: - Major Categories

extension SemanticInfoMap {
    func category(
        for syntax: DeclSyntaxProtocol,
        _ action: (inout AssociatedSyntaxMap) -> Void)
    {
        switch syntax.syntaxNodeType {
        case is ProtocolDeclSyntax.Type:
            action(&protocols)
        case is TypeAliasDeclSyntax.Type:
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
        case is SwitchExprSyntax.Type:
            action(&switches)
        default:
            break
        }
    }
    
    func category(
        for syntaxEnum: SyntaxEnum,
        _ action: (inout AssociatedSyntaxMap) -> Void)
    {
        switch syntaxEnum {
        case .protocolDecl:
            action(&protocols)
        case .typeAliasDecl:
            action(&typeAliases)
        case .variableDecl:
            action(&variables)
        case .classDecl:
            action(&classes)
        case .enumDecl:
            action(&enumerations)
        case .extensionDecl:
            action(&extensions)
        case .functionDecl:
            action(&functions)
        case .structDecl:
            action(&structs)
        case .switchExpr:
            action(&switches)
        default:
            break
        }
    }
    
    var isEmpty: Bool {
        semanticsLookupBySyntaxId.isEmpty
        && syntaxIDLookupByNodeId.isEmpty
        && structs.isEmpty
        && classes.isEmpty
        && enumerations.isEmpty
        && functions.isEmpty
        && variables.isEmpty
        && typeAliases.isEmpty
        && protocols.isEmpty
        && initializers.isEmpty
        && deinitializers.isEmpty
        && extensions.isEmpty
        && switches.isEmpty
    }
}

