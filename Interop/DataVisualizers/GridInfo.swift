//
//  GridInfo.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 10/26/21.
//

import Foundation
import SwiftSyntax
import SceneKit

typealias GridAssociationType = Set<SCNNode>
typealias GridCollection = [SyntaxIdentifier: GridAssociationType]

public class CodeGridAssociations {
	var textCache = [SyntaxIdentifier: String]() 
	var allSheets = GridCollection()
	var structs = GridCollection()
	var classes = GridCollection()
	var enumerations = GridCollection()
	var functions = GridCollection()
	var variables = GridCollection()
	var typeAliases = GridCollection()
	var protocols = GridCollection()
	var initializers = GridCollection()
	var deinitializers = GridCollection()
	var extensions = GridCollection()
	
	static func + (left: CodeGridAssociations, right: CodeGridAssociations) -> CodeGridAssociations {
		left.allSheets.merge(right.allSheets) { left, right in
//			print("Duplicated 'allSheets' key -> \(left.id), \(right.id)")
			return left
		}
		
		left.structs.merge(right.structs) { left, right in
//			print("Duplicated 'structs' key -> \(left.id), \(right.id)")
			return left
		}
		
		left.classes.merge(right.classes) { left, right in
//			print("Duplicated 'classes' key -> \(left.id), \(right.id)")
			return left
		}
		
		left.enumerations.merge(right.enumerations) { left, right in
//			print("Duplicated 'enumerations' key -> \(left.id), \(right.id)")
			return left
		}
		
		left.functions.merge(right.functions) { left, right in
//			print("Duplicated 'functions' key -> \(left.id), \(right.id)")
			return left
		}
		
		left.variables.merge(right.variables) { left, right in
//			print("Duplicated 'variables' key -> \(left.id), \(right.id)")
			return left
		}
		
		left.typeAliases.merge(right.typeAliases) { left, right in
//			print("Duplicated 'typeAliases' key -> \(left.id), \(right.id)")
			return left
		}
		
		left.protocols.merge(right.protocols) { left, right in
//			print("Duplicated 'protocols' key -> \(left.id), \(right.id)")
			return left
		}
		
		left.initializers.merge(right.initializers) { left, right in
//			print("Duplicated 'initializers' key -> \(left.id), \(right.id)")
			return left
		}
		
		left.deinitializers.merge(right.deinitializers) { left, right in
//			print("Duplicated 'deinitializers' key -> \(left.id), \(right.id)")
			return left
		}
		
		left.extensions.merge(right.extensions) { left, right in
//			print("Duplicated 'extensions' key -> \(left.id), \(right.id)")
			return left
		}
		
		return left
	}
}

extension CodeGridAssociations {
	subscript(_ syntaxId: SyntaxIdentifier) -> GridAssociationType? {
		get { allSheets[syntaxId] }
	}
	
	subscript(_ syntax: Syntax) -> GridAssociationType? {
		get { allSheets[syntax.id] }
		set {
			let hash = syntax.id
			let existing = allSheets[hash] ?? []
			allSheets[hash] = existing.union(newValue ?? [])
			
			switch syntax.cachedType {
				case .structDecl(let decl):
					textCache[syntax.id] = decl.identifier.text
				case .classDecl(let  decl):
					textCache[syntax.id] = decl.identifier.text
				case .functionDecl(let  decl):
					textCache[syntax.id] = decl.identifier.text
				case .enumDecl(let  decl):
					textCache[syntax.id] = decl.identifier.text
//				case .extensionDecl(let  decl):
//					textCache[syntax.id] = decl.extendedType.
//				case .variableDecl(let  decl):
//					textCache[syntax.id] = decl.identifier.text
				case .typealiasDecl(let  decl):
					textCache[syntax.id] = decl.identifier.text
				default:
					break
			}
			
			if let decl = syntax.asProtocol(DeclSyntaxProtocol.self) {
				groupedBlocks(for: decl) {
					let existing = $0[hash] ?? []
					$0[hash] = existing.union(newValue ?? [])
				}
			}
		}
	}
	
	func groupedBlocks(for syntax: DeclSyntaxProtocol,
					   _ action: (inout GridCollection) -> Void) {
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

