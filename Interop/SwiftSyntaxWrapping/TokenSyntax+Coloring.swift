//
//  TokenSyntax+Coloring.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 5/9/22.
//

import Foundation
import SwiftSyntax

public extension TokenSyntax {
    static let languageKeywords = NSUIColor(displayP3Red: 0.8, green: 0.2, blue: 0.2, alpha: 1.0)
    static let controlFlowKeyword = NSUIColor(displayP3Red: 0.4, green: 0.6, blue: 0.6, alpha: 1.0)
    static let enumSwitchKeyword = NSUIColor(displayP3Red: 0.5, green: 0.5, blue: 0.7, alpha: 1.0)
    static let selfKeyword = NSUIColor(displayP3Red: 1.0, green: 0.6, blue: 0.8, alpha: 1.0)
    static let selfClassKeyword = NSUIColor(displayP3Red: 1.0, green: 0.8, blue: 0.9, alpha: 1.0)
    static let standardScopeColor = NSUIColor(displayP3Red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
    static let actionableTokenColor = NSUIColor(displayP3Red: 1.0, green: 0.5, blue: 0.5, alpha: 1.0)
    static let rawRegexString = NSUIColor(displayP3Red: 0.4, green: 0.4, blue: 0.9, alpha: 1.0)
    static let rawRegexStringSlash = NSUIColor(displayP3Red: 0.8, green: 0.7, blue: 0.9, alpha: 1.0)
    static let stringLiteral = NSUIColor(displayP3Red: 0.8, green: 0.3, blue: 0.2, alpha: 1.0)
    static let valueToken = NSUIColor(displayP3Red: 0.5, green: 0.5, blue: 0.0, alpha: 1.0)
    static let operatorToken = NSUIColor(displayP3Red: 1.0, green: 1.0, blue: 0.0, alpha: 1.0)
    static let wildcard = NSUIColor(displayP3Red: 0.3, green: 0.4, blue: 0.1234007, alpha: 1.0)
    static let unknownToken = NSUIColor(displayP3Red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0)
    
    var defaultColor: NSUIColor {
        switch tokenKind {
        case .eof:
            return NSUIColor(displayP3Red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
        case .keyword(_):
            return Self.languageKeywords
        case .leftParen:
            return Self.controlFlowKeyword
        case .rightParen:
            return Self.controlFlowKeyword
        case .leftBrace:
            return Self.standardScopeColor
        case .rightBrace:
            return Self.standardScopeColor
        case .leftSquareBracket:
            return Self.standardScopeColor
        case .rightSquareBracket:
            return Self.standardScopeColor
        case .leftAngle:
            return Self.standardScopeColor
        case .rightAngle:
            return Self.standardScopeColor
        case .period:
            return Self.standardScopeColor
        case .prefixOperator(_):
            return Self.standardScopeColor
        case .comma:
            return Self.standardScopeColor
        case .ellipsis:
            return Self.standardScopeColor
        case .colon:
            return Self.standardScopeColor
        case .semicolon:
            return Self.standardScopeColor
        case .equal:
            return Self.standardScopeColor
        case .atSign:
            return Self.actionableTokenColor
        case .pound:
            return Self.actionableTokenColor
        case .prefixAmpersand:
            return Self.actionableTokenColor
        case .arrow:
            return Self.standardScopeColor
        case .backtick:
            return Self.standardScopeColor
        case .backslash:
            return Self.standardScopeColor
        case .exclamationMark:
            return Self.actionableTokenColor
        case .postfixQuestionMark:
            return Self.actionableTokenColor
        case .infixQuestionMark:
            return Self.actionableTokenColor
        case .stringQuote:
            return Self.standardScopeColor
        case .singleQuote:
            return Self.standardScopeColor
        case .multilineStringQuote:
            return Self.standardScopeColor
        case .poundSourceLocationKeyword:
            return Self.actionableTokenColor
        case .poundIfKeyword:
            return Self.actionableTokenColor
        case .poundElseKeyword:
            return Self.actionableTokenColor
        case .poundElseifKeyword:
            return Self.actionableTokenColor
        case .poundEndifKeyword:
            return Self.actionableTokenColor
        case .poundAvailableKeyword:
            return Self.actionableTokenColor
        case .integerLiteral(_):
            return Self.valueToken
        case .floatingLiteral(_):
            return Self.valueToken
        case .unknown(_):
            return Self.unknownToken
        case .identifier(_):
            return Self.valueToken
        case .postfixOperator(_):
            return Self.standardScopeColor
        case .dollarIdentifier(_):
            return Self.actionableTokenColor
        case .rawStringDelimiter(_):
            return Self.valueToken
        case .stringSegment(_):
            return Self.valueToken
        case .regexLiteralPattern(_):
            return Self.rawRegexString
        case .binaryOperator(_):
            return Self.operatorToken
        case .extendedRegexDelimiter(_):
            return Self.rawRegexString
        case .poundUnavailableKeyword:
            return Self.languageKeywords
        case .regexSlash:
            return Self.rawRegexStringSlash
        case .wildcard:
            return Self.wildcard
        }
    }
}
