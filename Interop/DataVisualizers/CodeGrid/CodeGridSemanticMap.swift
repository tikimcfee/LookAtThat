//
//  GridInfo.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 10/26/21.
//

import Foundation
import SwiftSyntax
import SceneKit

typealias SemanticsLookupSyntaxKey = SyntaxIdentifier
typealias SemanticsLookupSyntaxValueType = SemanticInfo
typealias SemanticsLookupNodeKey = String

typealias GridAssociationType = Array<SCNNode>
//typealias GridAssociationType = Set<SCNNode>

typealias GridAssociationSemanticsLookupByNodeId = MutableHolder<SemanticsLookupNodeKey, SemanticsLookupSyntaxKey>
typealias GridAssociationSemanticsLookupBySyntaxId = MutableHolder<SemanticsLookupSyntaxKey, SemanticsLookupSyntaxValueType>
typealias GridAssociationSyntaxToNodeType = MutableHolder<SyntaxIdentifier, GridAssociationType>
//typealias GridAssociationSyntaxToNodeType = [SyntaxIdentifier: GridAssociationType]

class MutableHolder<KeyType: Hashable, ValueType>{
//    private let dictionary: NSMutableDictionary = NSMutableDictionary()
    private lazy var dictionary: [KeyType: ValueType] = {
        var root = [KeyType: ValueType]()
//        root.reserveCapacity(reservedSize)
        return root
    }()

//    var isEmpty: Bool { dictionary.count <= 0 }
//    var keys: [KeyType] { dictionary.allKeys.compactMap { $0 as? KeyType} }
    private let reservedSize: Int
    var isEmpty: Bool { dictionary.isEmpty }
    var keys: [KeyType] { Array(dictionary.keys) }
    var info: String { "cap:\(dictionary.capacity)" }
    
    // Reserved syntax association counts for large files. The memory. It is consumed.
    init(_ reservedSize: Int) {
        self.reservedSize = reservedSize
    }
        
    subscript (_ key: KeyType) -> ValueType? {
//        get { dictionary[key] as? ValueType }
//        set { dictionary[key] = newValue }
        get { dictionary[key] }
        set { dictionary[key] = newValue }
    }
    
    func merge(_ other: MutableHolder,
               uniquingKeysWith combine: (ValueType, ValueType) throws -> ValueType ) rethrows {
        
        for (incomingKey, incomingValue) in other.dictionary {
            dictionary[incomingKey] = dictionary[incomingKey] ?? incomingValue
            
//            guard let incomingCastKey = incomingKey as? KeyType,
//                  let incomingCastValue = incomingValue as? ValueType,
//                  let currentCastValue = dictionary[incomingKey] as? ValueType else {
//                      print("""
//Found value in dictionary with invalid types:
//\(incomingKey)
//\(incomingValue)
//\(String(describing: dictionary[incomingKey]))
//""")
//                return
//            }
//            dictionary[incomingCastKey] = castMerge(incomingCastKey, currentCastValue, incomingCastValue)
        }
    }
    
    private func unsafeMerge(_ key: KeyType, _ left: ValueType?, _ right: ValueType?) -> ValueType? {
        if right != nil && left != nil {
            print("Overwriting in merge: \(key) \(String(describing: left)) <-- \(String(describing: right))")
        }
        return left ?? right
    }
    
    private func castMerge(_ key: KeyType, _ left: ValueType?, _ right: ValueType?) -> ValueType? {
        if right != nil && left != nil {
            print("Overwriting in merge: \(key) \(String(describing: left)) <-- \(String(describing: right))")
        }
        return left ?? right
    }
    
}

public class CodeGridSemanticMap {
	
	// TODO: Having separate caches is kinda lame
	// I'd like to find a way to use a shared key between node look and syntax lookup.
	// I may just need to go back and replace all the SyntaxIdentifier's with simple strings.
	var semanticsLookupBySyntaxId = GridAssociationSemanticsLookupBySyntaxId(10_000)
	var semanticsLookupByNodeId = GridAssociationSemanticsLookupByNodeId(10_000)
	var syntaxIdToTokenNodes = GridAssociationSyntaxToNodeType(10_000) // [SyntaxIdentifier: GridAssociationType]

    var structs = GridAssociationSyntaxToNodeType(1000)
    var classes = GridAssociationSyntaxToNodeType(1000)
    var enumerations = GridAssociationSyntaxToNodeType(1000)
    var functions = GridAssociationSyntaxToNodeType(1000)
    var variables = GridAssociationSyntaxToNodeType(1000)
    var typeAliases = GridAssociationSyntaxToNodeType(1000)
    var protocols = GridAssociationSyntaxToNodeType(1000)
    var initializers = GridAssociationSyntaxToNodeType(1000)
    var deinitializers = GridAssociationSyntaxToNodeType(1000)
    var extensions = GridAssociationSyntaxToNodeType(1000)
    
    func dump() {
        print(semanticsLookupBySyntaxId.info) // RidiculousFile == 49152
        print(semanticsLookupByNodeId.info)   // RidiculousFile == 24576
        print(syntaxIdToTokenNodes.info)   // RidiculousFile == 24576
        
        [structs, classes, enumerations,
         functions, variables, typeAliases,
         protocols, initializers, deinitializers,
         extensions].forEach {
            print($0.info)
        }
    }
	
	static func + (left: CodeGridSemanticMap, right: CodeGridSemanticMap) -> CodeGridSemanticMap {
		
		left.syntaxIdToTokenNodes.merge(right.syntaxIdToTokenNodes, uniquingKeysWith: takeLeft)
		left.structs.merge(right.structs, uniquingKeysWith: takeLeft)
		left.classes.merge(right.classes, uniquingKeysWith: takeLeft)
		left.enumerations.merge(right.enumerations, uniquingKeysWith: takeLeft)
		left.functions.merge(right.functions, uniquingKeysWith: takeLeft)
		left.variables.merge(right.variables, uniquingKeysWith: takeLeft)
		left.typeAliases.merge(right.typeAliases, uniquingKeysWith: takeLeft)
		left.protocols.merge(right.protocols, uniquingKeysWith: takeLeft)
		left.initializers.merge(right.initializers, uniquingKeysWith: takeLeft)
		left.deinitializers.merge(right.deinitializers, uniquingKeysWith: takeLeft)
		left.extensions.merge(right.extensions, uniquingKeysWith: takeLeft)
		
		return left
	}
	
	private static func takeLeft(_ left: GridAssociationType,  _ right: GridAssociationType) -> GridAssociationType {
		print("<!> Duplicated gridAssociations key -> \(left.map { $0.name }), \(right.map { $0.name })")
		return left
	}
}

extension CodeGridSemanticMap {
    func tokenNodes(_ syntaxId: SyntaxIdentifier) -> GridAssociationType? {
		syntaxIdToTokenNodes[syntaxId]
	}
	
	func semanticsFromNodeId(_ nodeId: SemanticsLookupNodeKey?) -> SemanticInfo? {
		guard let nodeId = nodeId,
			  let syntaxId = semanticsLookupByNodeId[nodeId],
			  let syntaxSemantics = semanticsLookupBySyntaxId[syntaxId]
		else { return nil }
		return syntaxSemantics
	}
    
    func parentList(_ nodeId: SemanticsLookupNodeKey) -> [SemanticInfo] {
        var parentList = [SemanticInfo]()
        walkToRootFrom(nodeId) { info in
            parentList.append(info)
        }
        return parentList
    }
    
    func walkToRootFrom(_ nodeId: SemanticsLookupNodeKey?, _ walker: (SemanticInfo) -> Void) {
        guard let nodeId = nodeId,
              let syntaxId = semanticsLookupByNodeId[nodeId] else {
            return
        }
        
        var maybeSemantics: SemanticInfo? = semanticsLookupBySyntaxId[syntaxId]
        while let semantics = maybeSemantics {
            walker(semantics)
            if let maybeParentId = semantics.node.parent?.id {
                maybeSemantics = semanticsLookupBySyntaxId[maybeParentId]
            } else {
                maybeSemantics = nil
            }
        }
    }
	
	func mergeSemanticInfo(_ syntaxId: SemanticsLookupSyntaxKey, 
						   _ nodeId: SemanticsLookupNodeKey,
						   _ semanticInfo: @autoclosure () -> SemanticInfo) {
		guard semanticsLookupBySyntaxId[syntaxId] == nil else { return }
		let newInfo = semanticInfo()
		
		semanticsLookupByNodeId[nodeId] = syntaxId
		semanticsLookupBySyntaxId[syntaxId] = newInfo
	}

	func mergeSyntaxAssociations(_ syntax: Syntax, _ uncheckedNewValue: GridAssociationType) {
		let syntaxId = syntax.id
        
//        var spaceCheckedValue: GridAssociationType
//        if var existing = syntaxIdToTokenNodes[syntaxId] {
////            existing.formUnion(uncheckedNewValue)
//            spaceCheckedValue = existing
//        } else {
//            var newSizedAssociation = GridAssociationType()
//            newSizedAssociation.reserveCapacity(5000)
//            newSizedAssociation.formUnion(uncheckedNewValue)
//            spaceCheckedValue = newSizedAssociation
//        }
//        syntaxIdToTokenNodes[syntaxId] = spaceCheckedValue
        
        var existing = syntaxIdToTokenNodes[syntaxId] ?? GridAssociationType()
        existing.append(contentsOf: uncheckedNewValue)
        syntaxIdToTokenNodes[syntaxId] = existing
		
		if let decl = syntax.asProtocol(DeclSyntaxProtocol.self) {
			category(for: decl) { category in
//                category[syntaxId] = existing.union(spaceCheckedValue)
                
				var existing = category[syntaxId] ?? []
                existing.append(contentsOf: uncheckedNewValue)
                category[syntaxId] = existing
			}
		}
	}
	
	func category(for syntax: DeclSyntaxProtocol,
					   _ action: (inout GridAssociationSyntaxToNodeType) -> Void) {
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

