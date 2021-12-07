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

class TraceFileWriter {
    let rewriter = TraceCapturingRewriter()
    
    func addTracesToFile(_ path: FileKitPath) {
        guard !path.isDirectoryFile else { return }
        do {
            let parsed = try SyntaxParser.parse(path.url)
            let rewritten = rewriter.visit(parsed)
            if let rewrittenData = rewritten.allText.data(using: .utf8) {
                try rewrite(data: rewrittenData, toPath: path.url, name: path.fileName)
            }
        } catch {
            print("Failed to parse [\(path.fileName)]: \(error)")
            return
        }
    }
    
    private func rewrite(data: Data, toPath file: URL, name: String) throws {
        let rewrittenFile = AppFiles.file(named: name, in: AppFiles.rewritesDirectory)
        print("Rewriting to \(rewrittenFile)")
        
        let handle = try FileHandle(forUpdating: rewrittenFile)
        try handle.truncate(atOffset: 0)
        handle.write(data)
        try handle.close()
    }
}

class TraceCapturingRewriter: SyntaxRewriter {
    var traceFunctionName: String { "laztrace" }
    
    private func nodeNeedsDecoration(_ node: FunctionDeclSyntax) -> Bool {
        if let body = node.body,
           let firstLine = body.statements.first?._syntaxNode.allText,
           firstLine.contains(traceFunctionName)
        {
            return false
        }
        return true
    }

    override func visit(_ node: FunctionDeclSyntax) -> DeclSyntax {
        guard nodeNeedsDecoration(node) else {
            return DeclSyntax(node)
        }
        
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
                    identifier: SyntaxFactory.makeIdentifier(traceFunctionName),
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
                    identifier: SyntaxFactory.makeIdentifier(callingName?.text ?? "<param_error>"),
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
