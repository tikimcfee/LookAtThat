//
//  CodeSheetVisitor+Directories.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 6/13/21.
//

import Foundation

extension CodeSheetVisitor {
    func renderDirectory(_ directory: Directory, in sceneState: SceneState) -> [ParsingState] {
        let results: [ParsingState] = directory.swiftUrls.compactMap { url in
            guard let state = try? makeFileSheet(url) else {
                print("Failed to load code file: \(url.lastPathComponent)")
                return nil
            }
            return state
        }
        
        // Small container object to immediately render results into
        // the scene, then toss away. This could also be a static function.
        CodeSheetDirectoryRenderer(render: results, in: sceneState)
        
        return results
    }
}
