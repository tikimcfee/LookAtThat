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

@inline(__always)
func laztrace(
    _ fileID: String,
    _ function: String,
    _ args: Any?...
) {
//    traceBox.laztrace(fileID, function, args)
}

func lazdump() {
    for call in traceBox.recordedCalls {
        print(call)
    }
}

class LaZTraceBox {
    struct Call: Equatable, CustomStringConvertible {
        let fileID: String
        let function: String
        let args: [Any?]
        var calls: Int = 1
        let queueName: String
        
        static func == (_ left: Call, _ right: Call) -> Bool {
            return left.fileID == right.fileID
                && left.function == right.function
                && left.queueName == right.queueName
        }
        
        mutating func increment() -> Call {
            self.calls += 1
            return self
        }
        
        var description: String {
            return "\(fileID).\(function).[\(calls)]~\(queueName)"
        }
    }
    
    let queue = DispatchQueue(label: "LaZTracing", qos: .background)
    var recordedCalls = [Call]()
    
    func laztrace(
        _ fileID: String,
        _ function: String,
        _ args: Any?...
    ) {
        let call = Call(
            fileID: fileID,
            function: function,
            args: args,
            queueName: currentQueueName()
        )
        queue.async {
            self.appendOrIncrement(call)
        }
    }
    
    private func appendOrIncrement(_ call: Call) {
        switch recordedCalls.last {
        case var .some(lastCall) where lastCall == call:
            recordedCalls[recordedCalls.endIndex - 1] = lastCall.increment()
        default:
            recordedCalls.append(call)
        }
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

class TracingFileFinder {
    private let toSkip = [
        ".git",
        ".xcodeproj",
        ".xcassets",
        "Libraries",
        "AppKitTests",
    ]
    
    func findFiles(_ root: String) -> [FileKitPath] {
        FileKitPath(root)
            .children(recursive: true)
            .filter(fileMatches)
    }
    
    private func fileMatches(_ path: FileKitPath) -> Bool {
        return path.pathExtension == "swift"
            && toSkip.allSatisfy { !path.url.absoluteString.contains($0) }
    }
}

class TraceCapturingRewriter: SyntaxRewriter {
    var traceFunctionName: String { "laztrace" }
    
    private func requiresRewrite(_ node: FunctionDeclSyntax) -> Bool {
        node.body?.statements.first?._syntaxNode
            .allText.contains(traceFunctionName) == true
    }

    override func visit(_ nodeToVisit: FunctionDeclSyntax) -> DeclSyntax {
        let safeCopy = requiresRewrite(nodeToVisit)
            ? nodeToVisit.withBody(nodeToVisit.body?.withStatements(nodeToVisit.body?.statements.removingFirst()))
            : nodeToVisit
        
        let functionParams = safeCopy.signature.input.parameterList
        
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
        
        let firstStatementTrivia = safeCopy.body?.statements.first?.leadingTrivia
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
        
        let laztraceNode = safeCopy.withBody(
            safeCopy.body?.withStatements(
                safeCopy.body?.statements.inserting(
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
