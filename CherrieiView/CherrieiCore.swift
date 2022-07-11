//
//  CherrieiCore.swift
//  CherrieiView
//
//  Created by Ivan Lugo on 7/10/22.
//

import Foundation
import ArgumentParser

private extension CherrieiRootCommand {
    static var arguments: [String] {
        get { CommandLine.arguments }
        set { CommandLine.arguments = newValue }
    }
    
    static var isDebugMode: Bool {
        arguments.contains("-NSDocumentRevisionsDebugMode")
    }
}

extension CherrieiRootCommand {
    static var cherrierArgumentPresent: Bool {
        CommandLine.arguments.contains("cherrier-test")
    }
    
    static func sanitizedMainRun() {
        if isDebugMode {
            arguments = Array(arguments[0...arguments.count - 3])
        }
        CherrieiRootCommand.main()
    }
}

private extension CherrieiRootCommand {
    struct Validated {
        let source: URL
        let target: URL
    }
    
    func createValidatedURLs() throws -> Validated {
        let target = target ?? source
        guard [source, target].allSatisfy(
            FileManager.default.fileExists(atPath:)
        ) else {
            throw CoreError.invalidArgs("<<\(source)>>, <<\(target)>>")
        }
        
        return Validated(
            source: URL(fileURLWithPath: source),
            target: URL(fileURLWithPath: target)
        )
    }
}

struct CherrieiRootCommand: ParsableCommand {
    
    @Argument var cherrieiTestFlag: String
    @Argument var source: String
    @Argument var target: String?
    
    mutating func run() throws {
        print("""
        Cherrier-flag:    present (\(cherrieiTestFlag))
        Cherrier-source:  '\(source)'
        Cherrier-target:  '\(target ?? "\(source) <default>")'
        """)
        
        try CherrieiCore.shared.launch(&self)
    }
}

enum CoreError: Error {
    case invalidArgs(String)
}

class CherrieiCore {
    
    static let shared = makeShared()
    
    
    private init() {
        
    }
    
    func launch(_ cl: inout CherrieiRootCommand) throws {
        let validated = try cl.createValidatedURLs()
        try renderValidatedPaths(validated)
    }
    
    private func renderValidatedPaths(_ validated: CherrieiRootCommand.Validated) throws {
        let cherrieiTarget = validated.target.appendingPathComponent(".cherriei-view.dae")
        
        print("Cherriei .dae target: \(cherrieiTarget.path)")
        startRender(sourcePath: validated.source, targetPath: cherrieiTarget)
    }
    
    private func startRender(
        sourcePath: URL,
        targetPath: URL
    ) {
        CodePagesController.shared.cherrieiRenderSceneFor(
            path: sourcePath,
            to: targetPath
        ) { result in
            showInFinder(url: targetPath)
            exit(0)
        }
    }
    
    private func writeDefaultCommandLine() throws {
        let absolute = "/Users/lugos/udev/manicmind/LookAtThat/Interop"
        let testPath = URL(fileURLWithPath: absolute)
        let outputPath = AppFiles.defaultSceneOutputFile
        
        startRender(sourcePath: testPath, targetPath: outputPath)
    }
    
    private static func makeShared() -> CherrieiCore {
        CherrieiCore()
    }
    
    private func trySelect() throws {
        openDirectory { selected in
            switch selected {
            case .success(let directory):
                let target = directory.parent.appendingPathComponent(".cherriei-view.dae")
                self.startRender(sourcePath: directory.parent, targetPath: target)
                
            case .failure(let error):
                print(error)
                break
            }
        }
    }
}
