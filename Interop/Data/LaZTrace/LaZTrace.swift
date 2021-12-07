//
//  LaZTrace.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 12/6/21.
//

import Foundation
import SwiftSyntax
import SwiftSyntaxParser

let traceBox = LaZTraceBox()
func laztrace(
    _ fileID: String,
    _ function: String,
    _ args: Any?...
) {
    traceBox.laztrace(fileID, function, args)
}

class LaZTraceBox {
    struct Call {
        let fileID: String
        let function: String
        let args: [Any?]
    }
    
    var recordedCalls = [Call]()
    
    func laztrace(
        _ fileID: String,
        _ function: String,
        _ args: Any?...
    ) {
        recordedCalls.append(
            Call(
                fileID: fileID,
                function: function,
                args: args
            )
        )
    }
}


class StateCapturingRewriter: SyntaxRewriter {
    let onVisit: (Syntax) -> SyntaxVisitorContinueKind
    let onVisitAnyPost: (Syntax) -> Void
    
    init(onVisitAny: @escaping (Syntax) -> SyntaxVisitorContinueKind,
         onVisitAnyPost: @escaping (Syntax) -> Void) {
        self.onVisit = onVisitAny
        self.onVisitAnyPost = onVisitAnyPost
    }
    
    override func visit(_ node: FunctionDeclSyntax) -> DeclSyntax {
        let functionParams = node.signature.input.parameterList
        
        var callingElements = functionParams.map { param -> TupleExprElementSyntax in
            let maybeComma = (functionParams.last != param)
                ? SyntaxFactory.makeCommaToken()
                : nil
            return tupleExprFromFunctionParam(param).withTrailingComma(maybeComma)
        }
        
        callingElements.insert(
            fileIDKeyword,
            at: 0
        )
        
        callingElements.insert(
            functionKeyword.withTrailingComma(
                !functionParams.isEmpty
                    ? SyntaxFactory.makeCommaToken()
                    : nil
            ),
            at: 1
        )
        
        var callExpr = laztraceExpression(callingElements)
        
        let firstStatementTrivia = node.body?.statements.first?.leadingTrivia
        let firstSpacingTrivia = firstStatementTrivia?.first(where: { piece in
            if case TriviaPiece.spaces = piece {
                return true
            } else if case TriviaPiece.tabs = piece {
                return true
            }
            return false
        })
        
        switch firstSpacingTrivia {
        case let .spaces(count):
            callExpr = callExpr.withLeadingTrivia(.newlines(1) + .spaces(count))
        case let .tabs(count):
            callExpr = callExpr.withLeadingTrivia(.newlines(1) + .tabs(count))
        default:
            break
        }
        
        let laztraceNode = node.withBody(
            node.body?.withStatements(
                node.body?.statements.inserting(
                    SyntaxFactory.makeCodeBlockItem(
                        item: Syntax(callExpr),
                        semicolon: nil,
                        errorTokens: nil
                    ),
                    at: 0
                )
            )
        )
        
        return DeclSyntax(laztraceNode)
    }
    
    func laztraceExpression(_ arguments: [TupleExprElementSyntax]) -> FunctionCallExprSyntax {
        SyntaxFactory.makeFunctionCallExpr(
            calledExpression: ExprSyntax(
                SyntaxFactory.makeIdentifierExpr(
                    identifier: SyntaxFactory.makeIdentifier("laztrace"),
                    declNameArguments: nil
                )
            ),
            leftParen: SyntaxFactory.makeLeftParenToken(),
            argumentList: SyntaxFactory.makeTupleExprElementList(arguments),
            rightParen: SyntaxFactory.makeRightParenToken(),
            trailingClosure: nil,
            additionalTrailingClosures: nil
        )
    }
    
    func tupleExprFromFunctionParam(_ param: FunctionParameterListSyntax.Element) -> TupleExprElementSyntax {
        let callingName = param.secondName ?? param.firstName
        let element = SyntaxFactory.makeTupleExprElement(
            label: nil,
            colon: nil,
            expression: ExprSyntax(
                SyntaxFactory.makeIdentifierExpr(
                    identifier: SyntaxFactory.makeIdentifier(callingName!.description),
                    declNameArguments: nil
                )
            ),
            trailingComma: nil
        )
        return element
    }
    
    var fileIDKeyword: TupleExprElementSyntax {
        SyntaxFactory.makeTupleExprElement(
            label: nil,
            colon: nil,
            expression: ExprSyntax(
                SyntaxFactory.makeIdentifierExpr(
                    identifier: SyntaxFactory.makePoundFileIDKeyword(),
                    declNameArguments: nil
                )
            ),
            trailingComma: SyntaxFactory.makeCommaToken()
        )
    }
    
    var functionKeyword: TupleExprElementSyntax {
        SyntaxFactory.makeTupleExprElement(
            label: nil,
            colon: nil,
            expression: ExprSyntax(
                SyntaxFactory.makeIdentifierExpr(
                    identifier: SyntaxFactory.makePoundFunctionKeyword(),
                    declNameArguments: nil
                )
            ),
            trailingComma: nil
        )
    }
}
