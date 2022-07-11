//
//  CherrieiCore.swift
//  CherrieiView
//
//  Created by Ivan Lugo on 7/10/22.
//

import Foundation

enum CoreError: Error {
    case invalidArgs(String)
}

class CherrieiCore {
    
    static let shared = makeShared()
    
    struct CherrieiBetaArgs {
        struct Validated {
            let source: URL
            let target: URL
        }
        let sourcePath: String
        let targetPath: String
        func validate() throws -> Validated {
            guard [sourcePath, targetPath]
                .allSatisfy(FileManager.default.fileExists(atPath:))
            else {
                throw CoreError.invalidArgs("Invalid path options:n\(sourcePath)\n\(targetPath)")
            }
            
            return Validated(
                source: URL(fileURLWithPath: sourcePath),
                target: URL(fileURLWithPath: targetPath)
            )
        }
    }
    
    private init() {
        
    }
    
    func launch() throws {
        let arguments = CommandLine.arguments
        print("--------------------------CherrieiView Launched----------------------------")
        print(arguments.forEach { print($0) })
        print("---------------------------------------------------------------------------")
        
        
        let args: CherrieiBetaArgs
        switch arguments.count {
        case 0...2:
            print("0/2 args")
            exit(1)
        case 3:
            print("Single path args")
            args = CherrieiBetaArgs(sourcePath: arguments[2], targetPath: arguments[2])
        case 4:
            print("Target path args")
            args = CherrieiBetaArgs(sourcePath: arguments[2], targetPath: arguments[3])
        default:
            print("Unknown args")
            exit(1)
        }
        
        let validated = try args.validate()
        startRender(sourcePath: validated.source, targetPath: validated.target)
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
}
