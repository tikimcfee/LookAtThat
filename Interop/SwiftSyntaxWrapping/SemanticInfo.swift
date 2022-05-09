//
//  SemanticInfo.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 4/24/22.
//

import Foundation
import SwiftSyntax

struct SemanticInfo: Hashable, CustomStringConvertible {
    let node: Syntax
    let syntaxId: SyntaxIdentifier
    
    // Refer to this semantic info by this name; it's displayable
    var fullTextSearch: String = ""
    var fileName: String = ""
    let referenceName: String
    let callStackName: String
    let syntaxTypeName: String
    let color: NSUIColor
    
    var description: String {
        "\(syntaxTypeName)~>[\(referenceName)]"
    }
    
    var isFullTextSearchable: Bool = false
    
    init(node: Syntax,
         referenceName: String? = nil,
         typeName: String? = nil,
         color: NSUIColor? = nil,
         fullTextSearchable: Bool = false,
         fileName: String? = nil,
         callStackName: String? = nil
    ) {
        self.node = node
        self.syntaxId = node.id
        self.referenceName = referenceName ?? ""
        self.syntaxTypeName = typeName ?? String(describing: node.syntaxNodeType)
        self.color = color ?? CodeGridColors.defaultText
        self.isFullTextSearchable = fullTextSearchable
        self.callStackName = callStackName ?? ""
        if isFullTextSearchable {
            self.fullTextSearch = node.strippedText
        }
        self.fileName = fileName ?? ""
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(syntaxId.hashValue)
        hasher.combine(referenceName.hashValue)
    }
}

extension SemanticInfo {
    func iterateReferenceKeys(_ receiver: (String) -> Void) {
        receiver(referenceName)
        receiver(referenceName.lowercased())
        receiver(referenceName.uppercased())
        
        referenceName.iterateTrieKeys(receiver: receiver)
    }
}
