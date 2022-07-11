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
    lazy var arguments = CommandLine.arguments
    
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
                throw CoreError.invalidArgs("<<\(sourcePath)>>, <<\(targetPath)>>")
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
        print("--------------------------CherrieiView Launched----------------------------")
        print(arguments.forEach { print($0) })
        print("---------------------------------------------------------------------------")
        
        try tryCLI()
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
    
    private func tryCLI() throws {
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
            if arguments.contains("-NSDocumentRevisionsDebugMode") {
                print("Xcode path args")
                args = CherrieiBetaArgs(sourcePath: arguments[2], targetPath: arguments[2])
            } else {
                print("Unknown args")
                exit(1)
            }
        }
        
        let validated = try args.validate()
        let cherrieiTarget = validated.target.appendingPathComponent(".cherriei-view.dae")
        
        print("RenderPlan, write scene for Cherrier:")
        print(cherrieiTarget.path)
        
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
}
