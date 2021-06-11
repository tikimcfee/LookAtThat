//
//  SwiftSyntax+FileLoading.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 6/9/21.
//

import Foundation
import SwiftSyntax

// File loading
public protocol SwiftSyntaxFileLoadable {
    func parse(_ source: String) -> SourceFileSyntax?
}

public extension SwiftSyntaxFileLoadable {
    func parse(_ source: String) -> SourceFileSyntax? {
        do {
            return try SyntaxParser.parse(source: source)
        } catch {
            print("|InvalidRawSource| failed to load > \(error)")
            return nil
        }
    }
    
    func loadSourceUrl(_ url: URL) -> SourceFileSyntax? {
        do {
            return try SyntaxParser.parse(url)
        } catch {
            print("|\(url)| failed to load > \(error)")
            return nil
        }
    }
}
