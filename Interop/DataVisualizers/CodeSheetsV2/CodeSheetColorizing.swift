//
//  CodeSheetColorizing.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 6/11/21.
//

import Foundation
import SwiftSyntax

class CodeSheetColorizing {
    
    func backgroundColor(for type: Syntax) -> NSUIColor {
        return typeColor(for: type.cachedType)
    }
    
    func typeColor(for type: SyntaxEnum) -> NSUIColor {
        switch type {
        case .structDecl:
            return color(0.3, 0.2, 0.3, 1.0)
        case .classDecl:
            return color(0.2, 0.2, 0.4, 1.0)
        case .functionDecl:
            return color(0.15, 0.15, 0.3, 1.0)
        case .enumDecl:
            return color(0.1, 0.3, 0.4, 1.0)
        case .extensionDecl:
            return color(0.2, 0.4, 0.4, 1.0)
        case .variableDecl:
            return color(0.3, 0.3, 0.3, 1.0)
        case .typealiasDecl:
            return color(0.5, 0.3, 0.5, 1.0)
        default:
            return color(0.2, 0.2, 0.2, 1.0)
        }
    }
    
    private func color(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat, _ alpha: CGFloat)  -> NSUIColor {
        return NSUIColor(displayP3Red: red, green: green, blue: blue, alpha: alpha)
    }
}
