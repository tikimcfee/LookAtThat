//
//  CherrieiCommands.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 7/11/22.
//

import Foundation
import ArgumentParser

struct CherrieiRootCommand: ParsableCommand {
    
    @Argument var cherrieiTestFlag: String
    @Argument var source: String
    @Argument var target: String?
    
    mutating func run() throws {
        print("""
        Cherrier-flag:    present (\(cherrieiTestFlag))
        Cherrier-source:  '\(source)'
        Cherrier-target:  '\(target ?? "<default>")'
        """)
        
        try CherrieiCore.shared.launch(&self)
    }
}

extension CherrieiRootCommand {
    static var cherrierArgumentPresent: Bool {
        CommandLine.arguments.contains("cherriei-test")
    }
    
    static func sanitizedMainRun() {
        if isDebugMode {
            arguments = Array(arguments[0...arguments.count - 3])
        }
        CherrieiRootCommand.main()
    }
}

extension CherrieiRootCommand {
    struct Validated {
        let source: URL
        let target: URL
    }
    
    func createValidatedURLs() throws -> Validated {
        guard FileManager.default.fileExists(atPath: source) else {
            throw CherrieiCoreError.invalidArgs("Path does not exist: \(source)")
        }
        
        let sourceUrl = URL(fileURLWithPath: source)
        let computedTarget: URL
        let targetPathName: String
        if let target = target {
            computedTarget = URL(fileURLWithPath: target)
            targetPathName = computedTarget.fileName
        } else {
            computedTarget = FileManager.default.temporaryDirectory
            targetPathName = sourceUrl.fileName
//            computedTarget = URL(fileURLWithPath: source)
        }
        
        let cherrieiContainer = computedTarget.appendingPathComponent(".cherriei-root")
        try FileManager.default.createDirectory(at: cherrieiContainer, withIntermediateDirectories: true)
        let cherrieiFinalTarget = cherrieiContainer.appendingPathComponent("\(targetPathName).cherriei.dae")
        
        return Validated(
            source: sourceUrl,
            target: cherrieiFinalTarget
        )
    }
}

private extension CherrieiRootCommand {
    static var arguments: [String] {
        get { CommandLine.arguments }
        set { CommandLine.arguments = newValue }
    }
    
    static var isDebugMode: Bool {
        arguments.contains("-NSDocumentRevisionsDebugMode")
    }
}

