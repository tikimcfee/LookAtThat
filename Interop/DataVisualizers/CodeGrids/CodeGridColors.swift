//
//  CodeGridColors.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 4/24/22.
//

import Foundation

class CodeGridColors {
    static let structDecl = color(0.3, 0.2, 0.3, 1.0)
    static let classDecl = color(0.2, 0.2, 0.4, 1.0)
    static let functionDecl = color(0.15, 0.15, 0.3, 1.0)
    static let enumDecl = color(0.1, 0.3, 0.4, 1.0)
    static let extensionDecl = color(0.2, 0.4, 0.4, 1.0)
    static let variableDecl = color(0.3, 0.3, 0.3, 1.0)
    static let typealiasDecl = color(0.5, 0.3, 0.5, 1.0)
    static let defaultText = color(0.2, 0.2, 0.2, 1.0)
    
    static let trivia = color(0.8, 0.8, 0.8, 0.5)
    
    static func color(_ red: VectorFloat,
                      _ green: VectorFloat,
                      _ blue: VectorFloat,
                      _ alpha: VectorFloat)  -> NSUIColor {
        NSUIColor(displayP3Red: red.cg, green: green.cg, blue: blue.cg, alpha: alpha.cg)
    }
}
