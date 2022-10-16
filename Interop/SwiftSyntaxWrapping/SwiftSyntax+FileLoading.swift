//
//  SwiftSyntax+FileLoading.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 6/9/21.
//

import Foundation
import SwiftSyntax
import SwiftParser

// File loading
public protocol SwiftSyntaxFileLoadable {
    func parse(_ source: String) -> SourceFileSyntax
    func loadSourceUrl(_ url: URL) -> SourceFileSyntax?
}

public extension SwiftSyntaxFileLoadable {
    func parse(_ source: String) -> SourceFileSyntax {
        Parser.parse(source: source)
    }
    
    func loadSourceUrl(_ url: URL) -> SourceFileSyntax? {
        do {
            let source = try String(contentsOf: url)
            return Parser.parse(source: source)
        } catch {
            print("|\(url)| failed to load > \(error)")
            return nil
        }
    }
}
