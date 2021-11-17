//
//  CodeGridTests.swift
//  LookAtThat_AppKitTests
//
//  Created by Ivan Lugo on 11/17/21.
//

import XCTest
import SwiftSyntax
import SwiftSyntaxParser
import SceneKit
import SwiftTrace
import Foundation
@testable import LookAtThat_AppKit

class LookAtThat_AppKitCodeGridTests: XCTestCase {
    var bundle: TestBundle!
    
    override func setUpWithError() throws {
        // Fields reset on each test!
        bundle = TestBundle()
        try bundle.setUpWithError()
        
    }
    
    override func tearDownWithError() throws {
        try bundle.tearDownWithError()
    }
    
    func testGridSizing() throws {
        bundle.gridParser.loadSourceUrl(bundle.testFile)?.tokens.forEach {
            print($0.triviaAndText)
            $0.triviaAndText.forEach {
                let (geometry, size) = bundle.glyphs[
                    GlyphCacheKey("\($0)", NSUIColor.white)
                ]
                
                print(size, "--", geometry.lengthX, geometry.lengthY, geometry.lengthZ)
                XCTAssertEqual(size.width, geometry.lengthX, accuracy: 0.0)
                XCTAssertEqual(size.height, geometry.lengthY, accuracy: 0.0)
            }
        }
    }
    
    func testSemanticInfo() throws {
        let sourceFile = try bundle.loadTestSource()
        let sourceSyntax = Syntax(sourceFile)
        //        grids.consume(syntax: sourceSyntax)
        
        func onVisit(_ syntax: Syntax) -> SyntaxVisitorContinueKind {
            //            let info = bundle.semanticBuilder.semanticInfo(for: syntax)
            //            print(info)
            return .visitChildren
        }
        
        func onVisitPost(_ syntax: Syntax) {
            
        }
        
        let visitor = StateCapturingVisitor(
            onVisitAny: onVisit,
            onVisitAnyPost: onVisitPost
        )
        
        visitor.walk(sourceSyntax)
    }
    
    func testAttributedWrites() throws {
        let testFile = bundle.testFile
        let fileData = try Data(contentsOfPath: FileKitPath(testFile.path))
        let dataString = try XCTUnwrap(String(data: fileData, encoding: .utf8))
        
        let dataStringAttributed = NSMutableAttributedString(
            string: dataString,
            attributes: [.foregroundColor: NSUIColor.red]
        )
        let appendedTestString = NSMutableAttributedString(
            string: "yet this is dog",
            attributes: [.foregroundColor: NSUIColor.blue]
        )
        dataStringAttributed.append(appendedTestString)
        
        let transformer = WireDataTransformer()
        let encodedTest = try XCTUnwrap(transformer.encodeAttributedString(dataStringAttributed))
        let (decodedTest, _) = try transformer.decodeAttributedString(encodedTest)
        print("Size of encode: \(encodedTest.mb)mb")
        XCTAssert(decodedTest == dataStringAttributed, "AttributedString write and re-read didn't reeturn same attributes")
    }
    
    func testSemanticWordGridEditor() throws {
        let editor = WorldGridEditor()
        
        var expected = FocusPosition()
        let start = editor.focusPosition
        XCTAssertEqual(start, expected, "start off from expected origin")
        
        expected = FocusPosition(x: expected.x + 1)
        editor.shiftFocus(.right)
        XCTAssertEqual(editor.focusPosition, expected, "start off from expected origin")
    }
    
    func testRewriting() throws {
        
        let testTraceCall = """
func laztrace(
    _ file: String = #fileID,
    _ function: String = #function,
    _ args: Any...
) {
  print(file, function, args)
}
"""
        
        let testSource = """
func foo(_ ivan: String) {
  print("hello, world")
}

func bar(lugo: String) {
  print("goodbye, franke")
}

func gnar() {
  print("flibble, flooble")
}

func gingunkafunk(a: String, b: String, c: String, aReallyLongOne: String, _ mrTripUUp: String) {
  print("goodbye, franke")
}

func johnny() {
  func go() {
    func deeper() {
        print("lul")
    }
  }
}
"""
        
        let rewriter = StateCapturingRewriter(
            onVisitAny: { node in
                return .visitChildren
            },
            onVisitAnyPost: { _ in
                
            }
        )
        let parsed = try! SyntaxParser.parse(source: testSource)
        let rewritten = rewriter.visit(parsed)
        print(rewritten.description)
    }
    
}

class StateCapturingRewriter: SyntaxRewriter {
    let onVisit: (Syntax) -> SyntaxVisitorContinueKind
    let onVisitAnyPost: (Syntax) -> Void
    
    lazy var callTrace = """
laztrace()
"""
    lazy var callSyntax = try! SyntaxParser.parse(source: callTrace)
    
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
