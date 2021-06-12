//
//  CodeSheetColorizing.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 6/11/21.
//

import Foundation
import SwiftSyntax

class CodeSheetColorizing {
    func backgroundColor(for syntax: Syntax) -> NSUIColor {
        return typeColor(for: syntax.syntaxNodeType)
    }
    
    func typeColor(for type: SyntaxProtocol.Type) -> NSUIColor {
        if type == StructDeclSyntax.self {
            return color(0.3, 0.2, 0.3, 1.0)
        }
        if type == ClassDeclSyntax.self {
            return color(0.2, 0.2, 0.4, 1.0)
        }
        if type == FunctionDeclSyntax.self {
            return color(0.15, 0.15, 0.3, 1.0)
        }
        if type == EnumDeclSyntax.self {
            return color(0.1, 0.3, 0.4, 1.0)
        }
        if type == ExtensionDeclSyntax.self {
            return color(0.2, 0.4, 0.4, 1.0)
        }
        if type == VariableDeclSyntax.self {
            return color(0.3, 0.3, 0.3, 1.0)
        }
        if type == TypealiasDeclSyntax.self {
            return color(0.5, 0.3, 0.5, 1.0)
        }
        else {
            return color(0.2, 0.2, 0.2, 1.0)
        }
    }
    
    private func color(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat, _ alpha: CGFloat)  -> NSUIColor {
        return NSUIColor(displayP3Red: red, green: green, blue: blue, alpha: alpha)
    }
}
