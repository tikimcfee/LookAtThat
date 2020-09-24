import SwiftSyntax

extension SwiftSyntax.TriviaPiece {
    var stringify: String {
        var output = ""
        write(to: &output)
        return output
    }
}

extension Trivia {
    var stringified: String {
        return map { $0.stringify }.joined()
    }
}

extension TokenSyntax {

    var typeName: String { return String(describing: tokenKind) }

    var alltext: String {
        leadingTrivia.stringified
        .appending(text)
        .appending(trailingTrivia.stringified)
    }

    typealias SelectionInfo = (String)

    func registeredName(in info: inout SourceInfo) -> String {
        switch tokenKind {
        case let .identifier(text):
            info.identifiers.insert(text)
            return text
        case let .stringLiteral(text):
            info.strings.insert(text)
            return "'\(text)'"
        case let .integerLiteral(text),
             let .floatingLiteral(text):
            info.numbers.insert(text)
            return text
        default:
            info.allTokens[typeName].append(text)
            return typeName
//        case .eof:
//            <#code#>
//        case .associatedtypeKeyword:
//            <#code#>
//        case .deinitKeyword:
//            <#code#>
//        case .enumKeyword:
//            <#code#>
//        case .extensionKeyword:
//            <#code#>
//        case .funcKeyword:
//            <#code#>
//        case .importKeyword:
//            <#code#>
//        case .initKeyword:
//            <#code#>
//        case .inoutKeyword:
//            <#code#>
//        case .operatorKeyword:
//            <#code#>
//        case .precedencegroupKeyword:
//            <#code#>
//        case .protocolKeyword:
//            <#code#>
//        case .structKeyword:
//            <#code#>
//        case .subscriptKeyword:
//            <#code#>
//        case .typealiasKeyword:
//            <#code#>
//        case .fileprivateKeyword:
//            <#code#>
//        case .internalKeyword:
//            <#code#>
//        case .privateKeyword:
//            <#code#>
//        case .publicKeyword:
//            <#code#>
//        case .staticKeyword:
//            <#code#>
//        case .deferKeyword:
//            <#code#>
//        case .ifKeyword:
//            <#code#>
//        case .guardKeyword:
//            <#code#>
//        case .doKeyword:
//            <#code#>
//        case .repeatKeyword:
//            <#code#>
//        case .elseKeyword:
//            <#code#>
//        case .forKeyword:
//            <#code#>
//        case .inKeyword:
//            <#code#>
//        case .whileKeyword:
//            <#code#>
//        case .returnKeyword:
//            <#code#>
//        case .breakKeyword:
//            <#code#>
//        case .continueKeyword:
//            <#code#>
//        case .fallthroughKeyword:
//            <#code#>
//        case .switchKeyword:
//            <#code#>
//        case .caseKeyword:
//            <#code#>
//        case .defaultKeyword:
//            <#code#>
//        case .whereKeyword:
//            <#code#>
//        case .catchKeyword:
//            <#code#>
//        case .throwKeyword:
//            <#code#>
//        case .asKeyword:
//            <#code#>
//        case .anyKeyword:
//            <#code#>
//        case .falseKeyword:
//            <#code#>
//        case .isKeyword:
//            <#code#>
//        case .nilKeyword:
//            <#code#>
//        case .rethrowsKeyword:
//            <#code#>
//        case .superKeyword:
//            <#code#>
//        case .selfKeyword:
//            <#code#>
//        case .capitalSelfKeyword:
//            <#code#>
//        case .trueKeyword:
//            <#code#>
//        case .tryKeyword:
//            <#code#>
//        case .throwsKeyword:
//            <#code#>
//        case .__file__Keyword:
//            <#code#>
//        case .__line__Keyword:
//            <#code#>
//        case .__column__Keyword:
//            <#code#>
//        case .__function__Keyword:
//            <#code#>
//        case .__dso_handle__Keyword:
//            <#code#>
//        case .wildcardKeyword:
//            <#code#>
//        case .leftParen:
//            <#code#>
//        case .rightParen:
//            <#code#>
//        case .leftBrace:
//            <#code#>
//        case .rightBrace:
//            <#code#>
//        case .leftSquareBracket:
//            <#code#>
//        case .rightSquareBracket:
//            <#code#>
//        case .leftAngle:
//            <#code#>
//        case .rightAngle:
//            <#code#>
//        case .period:
//            <#code#>
//        case .prefixPeriod:
//            <#code#>
//        case .comma:
//            <#code#>
//        case .ellipsis:
//            <#code#>
//        case .colon:
//            <#code#>
//        case .semicolon:
//            <#code#>
//        case .equal:
//            <#code#>
//        case .atSign:
//            <#code#>
//        case .pound:
//            <#code#>
//        case .prefixAmpersand:
//            <#code#>
//        case .arrow:
//            <#code#>
//        case .backtick:
//            <#code#>
//        case .backslash:
//            <#code#>
//        case .exclamationMark:
//            <#code#>
//        case .postfixQuestionMark:
//            <#code#>
//        case .infixQuestionMark:
//            <#code#>
//        case .stringQuote:
//            <#code#>
//        case .singleQuote:
//            <#code#>
//        case .multilineStringQuote:
//            <#code#>
//        case .poundKeyPathKeyword:
//            <#code#>
//        case .poundLineKeyword:
//            <#code#>
//        case .poundSelectorKeyword:
//            <#code#>
//        case .poundFileKeyword:
//            <#code#>
//        case .poundFileIDKeyword:
//            <#code#>
//        case .poundFilePathKeyword:
//            <#code#>
//        case .poundColumnKeyword:
//            <#code#>
//        case .poundFunctionKeyword:
//            <#code#>
//        case .poundDsohandleKeyword:
//            <#code#>
//        case .poundAssertKeyword:
//            <#code#>
//        case .poundSourceLocationKeyword:
//            <#code#>
//        case .poundWarningKeyword:
//            <#code#>
//        case .poundErrorKeyword:
//            <#code#>
//        case .poundIfKeyword:
//            <#code#>
//        case .poundElseKeyword:
//            <#code#>
//        case .poundElseifKeyword:
//            <#code#>
//        case .poundEndifKeyword:
//            <#code#>
//        case .poundAvailableKeyword:
//            <#code#>
//        case .poundFileLiteralKeyword:
//            <#code#>
//        case .poundImageLiteralKeyword:
//            <#code#>
//        case .poundColorLiteralKeyword:
//            <#code#>
//        case .integerLiteral(_):
//            <#code#>
//        case .floatingLiteral(_):
//            <#code#>
//        case .stringLiteral(_):
//            <#code#>
//        case .unknown(_):
//            <#code#>
//        case .unspacedBinaryOperator(_):
//            <#code#>
//        case .spacedBinaryOperator(_):
//            <#code#>
//        case .postfixOperator(_):
//            <#code#>
//        case .prefixOperator(_):
//            <#code#>
//        case .dollarIdentifier(_):
//            <#code#>
//        case .contextualKeyword(_):
//            <#code#>
//        case .rawStringDelimiter(_):
//            <#code#>
//        case .stringSegment(_):
//            <#code#>
//        case .stringInterpolationAnchor:
//            <#code#>
//        case .yield:
//            <#code#>
        }
    }
}
