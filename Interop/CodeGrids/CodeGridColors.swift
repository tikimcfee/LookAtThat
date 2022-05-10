//
//  CodeGridColors.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 4/24/22.
//

import Foundation

class CodeGridColors {
    static let defaultText   = color(0.20, 0.20, 0.20, 1.00)
    static let trivia        = color(0.80, 0.80, 0.80, 0.50)
    
    static let classDecl     = color(0.20, 0.20, 0.40, 1.00)
    static let enumDecl      = color(0.10, 0.30, 0.40, 1.00)
    static let extensionDecl = color(0.20, 0.40, 0.40, 1.00)
    static let functionDecl  = color(0.15, 0.15, 0.30, 1.00)
    static let protocolDecl  = color(0.30, 0.50, 0.40, 0.95)
    static let structDecl    = color(0.30, 0.20, 0.30, 1.00)
    static let typealiasDecl = color(0.50, 0.30, 0.50, 1.00)
    static let variableDecl  = color(0.30, 0.30, 0.30, 1.00)
    static let memberAccess  = color(0.15, 0.15, 0.15, 1.00)
    
    static func color(_ red: VectorFloat,
                      _ green: VectorFloat,
                      _ blue: VectorFloat,
                      _ alpha: VectorFloat)  -> NSUIColor {
        NSUIColor(
            displayP3Red: red.cg,
            green: green.cg,
            blue: blue.cg,
            alpha: alpha.cg
        )
    }
}
