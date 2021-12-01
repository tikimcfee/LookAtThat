import SwiftSyntax
//import Parser

extension SyntaxIdentifier {
    var stringIdentifier: String { "\(hashValue)" }
}

extension SwiftSyntax.TriviaPiece {
    var stringify: String {
        var output = ""
        write(to: &output)
        return output
    }
}

extension Trivia {
    var stringified: String {
		// #^ check if write(to:) appends or overwrites to avoid this map and join
        return reduce(into: "") { $1.write(to: &$0) }
    }
}

extension Syntax {
    var allText: String {
        return tokens.reduce(into: "") { result, token in
            result.append(token.triviaAndText)
        }
    }
    
    var strippedText: String {
        return tokens.reduce(into: "") { result, token in
            result.append(token.text)
        }
    }
    
    func prefixedText(_ count: Int) -> String {
        return tokens.prefix(count).reduce(into: "") { result, token in
            result.append(token.text)
        }
    }
}

extension SyntaxChildren {
    func listOfChildren() -> String {
        reduce(into: "") { result, element in
            let elementList = element.children.listOfChildren()
            result.append(
                String(describing: element.syntaxNodeType)
            )
            result.append(
                "\n\t\t\(elementList)"
            )
            if element != last { result.append("\n\t") }
        }
    }
}

public extension TokenSyntax {
    var typeName: String { return String(describing: tokenKind) }

    var triviaAndText: String {
        leadingTrivia.stringified
        .appending(text)
        .appending(trailingTrivia.stringified)
    }

    var splitText: [String] {
        switch tokenKind {
        case let .stringSegment(literal):
            return literal.stringLines
        case let .stringLiteral(literal):
            return literal.stringLines
        default:
            return [text]
        }
    }
	
	static let languageKeywords = NSUIColor(displayP3Red: 0.8, green: 0.2, blue: 0.2, alpha: 1.0)
	static let controlFlowKeyword = NSUIColor(displayP3Red: 0.4, green: 0.6, blue: 0.6, alpha: 1.0)
	static let enumSwitchKeyword = NSUIColor(displayP3Red: 0.5, green: 0.5, blue: 0.7, alpha: 1.0)
	static let selfKeyword = NSUIColor(displayP3Red: 1.0, green: 0.6, blue: 0.8, alpha: 1.0)
	static let selfClassKeyword = NSUIColor(displayP3Red: 1.0, green: 0.8, blue: 0.9, alpha: 1.0)
	static let standardScopeColor = NSUIColor(displayP3Red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
	static let actionableTokenColor = NSUIColor(displayP3Red: 1.0, green: 0.5, blue: 0.5, alpha: 1.0)
	static let valueToken = NSUIColor(displayP3Red: 0.5, green: 0.5, blue: 0.0, alpha: 1.0)
	static let unknownToken = NSUIColor(displayP3Red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0)
    
    var defaultColor: NSUIColor {
        switch tokenKind {
			case .eof:
				return NSUIColor(displayP3Red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
			case .associatedtypeKeyword:
				return Self.languageKeywords 
			case .classKeyword:
				return Self.languageKeywords
			case .deinitKeyword:
				return Self.languageKeywords
			case .enumKeyword:
				return Self.languageKeywords
			case .extensionKeyword:
				return Self.languageKeywords
			case .funcKeyword:
				return Self.languageKeywords
			case .importKeyword:
				return Self.languageKeywords
			case .initKeyword:
				return Self.languageKeywords
			case .inoutKeyword:
				return Self.languageKeywords
			case .letKeyword:
				return Self.languageKeywords
			case .operatorKeyword:
				return Self.languageKeywords
			case .precedencegroupKeyword:
				return Self.languageKeywords
			case .protocolKeyword:
				return Self.languageKeywords
			case .structKeyword:
				return Self.languageKeywords
			case .subscriptKeyword:
				return Self.languageKeywords
			case .typealiasKeyword:
				return Self.languageKeywords
			case .varKeyword:
				return Self.languageKeywords
			case .fileprivateKeyword:
				return Self.languageKeywords
			case .internalKeyword:
				return Self.languageKeywords
			case .privateKeyword:
				return Self.languageKeywords
			case .publicKeyword:
				return Self.languageKeywords
			case .staticKeyword:
				return Self.languageKeywords
			case .deferKeyword:
				return Self.languageKeywords
			case .ifKeyword:
				return Self.controlFlowKeyword
			case .guardKeyword:
				return Self.controlFlowKeyword
			case .doKeyword:
				return Self.controlFlowKeyword
			case .repeatKeyword:
				return Self.controlFlowKeyword
			case .elseKeyword:
				return Self.controlFlowKeyword
			case .forKeyword:
				return Self.controlFlowKeyword
			case .inKeyword:
				return Self.controlFlowKeyword
			case .whileKeyword:
				return Self.controlFlowKeyword
			case .returnKeyword:
				return Self.controlFlowKeyword
			case .breakKeyword:
				return Self.controlFlowKeyword
			case .continueKeyword:
				return Self.controlFlowKeyword
			case .fallthroughKeyword:
				return Self.enumSwitchKeyword
			case .switchKeyword:
				return Self.enumSwitchKeyword
			case .caseKeyword:
				return Self.enumSwitchKeyword
			case .defaultKeyword:
				return Self.enumSwitchKeyword
			case .whereKeyword:
				return Self.controlFlowKeyword
			case .catchKeyword:
				return Self.controlFlowKeyword
			case .throwKeyword:
				return Self.controlFlowKeyword
			case .asKeyword:
				return Self.controlFlowKeyword
			case .anyKeyword:
				return Self.controlFlowKeyword
			case .falseKeyword:
				return Self.controlFlowKeyword
			case .isKeyword:
				return Self.controlFlowKeyword
			case .nilKeyword:
				return Self.controlFlowKeyword
			case .rethrowsKeyword:
				return Self.controlFlowKeyword
			case .superKeyword:
				return Self.controlFlowKeyword
			case .selfKeyword:
				return Self.selfKeyword
			case .capitalSelfKeyword:
				return Self.selfClassKeyword
			case .trueKeyword:
				return Self.controlFlowKeyword
			case .tryKeyword:
				return Self.controlFlowKeyword
			case .throwsKeyword:
				return Self.controlFlowKeyword
			case .__file__Keyword:
				return Self.controlFlowKeyword
			case .__line__Keyword:
				return Self.controlFlowKeyword
			case .__column__Keyword:
				return Self.controlFlowKeyword
			case .__function__Keyword:
				return Self.controlFlowKeyword
			case .__dso_handle__Keyword:
				return Self.controlFlowKeyword
			case .wildcardKeyword:
				return Self.controlFlowKeyword
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
			case .prefixPeriod:
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
			case .poundKeyPathKeyword:
				return Self.actionableTokenColor
			case .poundLineKeyword:
				return Self.actionableTokenColor
			case .poundSelectorKeyword:
				return Self.actionableTokenColor
			case .poundFileKeyword:
				return Self.actionableTokenColor
			case .poundFileIDKeyword:
				return Self.actionableTokenColor
			case .poundFilePathKeyword:
				return Self.actionableTokenColor
			case .poundColumnKeyword:
				return Self.actionableTokenColor
			case .poundFunctionKeyword:
				return Self.actionableTokenColor
			case .poundDsohandleKeyword:
				return Self.actionableTokenColor
			case .poundAssertKeyword:
				return Self.actionableTokenColor
			case .poundSourceLocationKeyword:
				return Self.actionableTokenColor
			case .poundWarningKeyword:
				return Self.actionableTokenColor
			case .poundErrorKeyword:
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
			case .poundFileLiteralKeyword:
				return Self.actionableTokenColor
			case .poundImageLiteralKeyword:
				return Self.actionableTokenColor
			case .poundColorLiteralKeyword:
				return Self.actionableTokenColor
			case .integerLiteral(_):
				return Self.valueToken
			case .floatingLiteral(_):
				return Self.valueToken
			case .stringLiteral(_):
				return Self.valueToken
			case .unknown(_):
				return Self.unknownToken
			case .identifier(_):
				return Self.valueToken
			case .unspacedBinaryOperator(_):
				return Self.standardScopeColor
			case .spacedBinaryOperator(_):
				return Self.standardScopeColor
			case .postfixOperator(_):
				return Self.standardScopeColor
			case .prefixOperator(_):
				return Self.standardScopeColor
			case .dollarIdentifier(_):
				return Self.actionableTokenColor
			case .contextualKeyword(_):
				return Self.actionableTokenColor
			case .rawStringDelimiter(_):
				return Self.valueToken
			case .stringSegment(_):
				return Self.valueToken
			case .stringInterpolationAnchor:
				return Self.valueToken
			case .yield:
				return Self.controlFlowKeyword
            case .poundUnavailableKeyword:
                return Self.actionableTokenColor
        }
    }
}
