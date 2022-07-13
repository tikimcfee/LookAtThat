//
//  CherrieiCore.swift
//  CherrieiView
//
//  Created by Ivan Lugo on 7/10/22.
//
// Spot-fronted Swift, Cypseloides cherriei
// https://ebird.org/species/spfswi1

import Foundation
import ArgumentParser

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
        print("Running with validated startup: \(validated)")
        startRender(sourcePath: validated.source, targetPath: validated.target) {
            print("Render Complete, exiting")
            exit(0)
        }
    }
    
    private func startRender(
        sourcePath: URL,
        targetPath: URL,
        _ completionReceiver: @escaping () -> Void
    ) {
        CodePagesController.shared.cherrieiRenderSceneFor(
            path: sourcePath,
            to: targetPath
        ) { result in
            showInFinder(url: targetPath)
            completionReceiver()
        }
    }
    
    private func startSelectableRender(
        sourcePath: URL,
        targetPath: URL
    ) {
        selectDirectory({
            $0.directoryURL = sourcePath
            $0.title = "CherrieiView Confirmation"
            $0.message = "CherrieiView will read from and run in the selected directory."
            $0.prompt = "Confirm selected directory"
        }) { result in
            switch result {
            case .success(let directory):
                let directory = directory.parent
                CodePagesController.shared.cherrieiRenderSceneFor(
                    path: directory,
                    to: targetPath
                ) { result in
                    showInFinder(url: targetPath)
                    exit(0)
                }
            case .failure(let error):
                print(error)
                exit(1)
            }
        }
    }
    
    private func writeDefaultCommandLine() throws {
        let absolute = "/Users/lugos/udev/manicmind/LookAtThat/Interop"
        let testPath = URL(fileURLWithPath: absolute)
        let outputPath = AppFiles.defaultSceneOutputFile
        
        startSelectableRender(sourcePath: testPath, targetPath: outputPath)
    }
    
    private static func makeShared() -> CherrieiCore {
        CherrieiCore()
    }
    
    private func trySelect() throws {
        openDirectory { selected in
            switch selected {
            case .success(let directory):
                let target = directory.parent.appendingPathComponent(".cherriei-view.dae")
                self.startSelectableRender(sourcePath: directory.parent, targetPath: target)
                
            case .failure(let error):
                print(error)
                break
            }
        }
    }
}
