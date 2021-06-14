//
//  CodeSheetParserV2.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 6/10/21.
//

import Foundation
import SwiftSyntax
import SceneKit

public class CodeSheetParserV2 {
    var textNodeBuilder: WordNodeBuilder
    let codeSheetVisitor: CodeSheetVisitor
    
    init(_ nodeBuilder: WordNodeBuilder) {
        self.textNodeBuilder = nodeBuilder
        self.codeSheetVisitor = CodeSheetVisitor(nodeBuilder)
    }
    
    func parseFile(_ url: URL) -> CodeSheet? {
        SCNNode.BoundsCaching.Clear()
        return try? codeSheetVisitor.makeFileSheet(url).sheet
    }
    
    func parseDirectory(_ directory: Directory,
                        in scene: SceneState,
                        _ handler: @escaping RenderDirectoryHandler) {
        SCNNode.BoundsCaching.Clear()
        let results = codeSheetVisitor.renderDirectory(directory, in: scene)
        handler(results)
    }
}
