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
    private static func makeShared() -> CherrieiCore {
        CherrieiCore()
    }
    static let shared = makeShared()
    
    private init() {
        
    }
    
    func launch() {
        print("--------------------------CherrieiView Launched----------------------------")
        print(CommandLine.arguments.forEach { print($0) })
        print("---------------------------------------------------------------------------")
        
        let absolute = "/Users/lugos/udev/manicmind/LookAtThat/Interop"
        let testPath = URL(fileURLWithPath: absolute)
        let outputPath = AppFiles.defaultSceneOutputFile
        
        CodePagesController.shared.cherrieiRenderSceneFor(
            path: testPath,
            to: outputPath
        ) { result in
            showInFinder(url: outputPath)
            exit(0)
        }
    }
    
    private func writeDefaultCommandLine() throws {
        let arguments = CommandLine.arguments
        

        guard arguments.contains("cherrier-test") else {
            throw CoreError.invalidArgs("missing test param")
        }
        
        
    }
}
