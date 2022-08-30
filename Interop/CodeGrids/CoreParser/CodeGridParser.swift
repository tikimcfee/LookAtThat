//
//  CodeGridParser.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 10/22/21.
//

import Foundation
import SwiftSyntax
import SceneKit
import SwiftUI

class CodeGridParser: SwiftSyntaxFileLoadable {
    
    let renderQueue = DispatchQueue(label: "RenderClock", qos: .userInitiated)
    var tokenCache: CodeGridTokenCache = CodeGridTokenCache()
    
    lazy var editorWrapper: CodeGridWorld = {
        let world = CodeGridWorld()
        return world
    }()
    
    lazy var gridCache = GlobalInstances.gridStore.gridCache
    lazy var concurrency = GlobalInstances.gridStore.concurrentRenderer
    lazy var query: CodeGridParserQueryController = {
        return CodeGridParserQueryController()
    }()
}

// MARK: - Rendering strategies
class RecurseState {
    let snapping = WorldGridSnapping()
}

class CodeGridWorld {
    typealias Receiver = (_ camera: SCNNode, _ root: SCNNode) -> Void
    
    init() {
        
    }
    
    func doInWorld(_ operation: Receiver) {
        print("not implemented!", #function)
    }
    
    func addInFrontOfCamera(grid: CodeGrid) {
        print("not implemented!", #function)
    }
    
    func addGrid(style: WorldGridEditor.AddStyle) {
        print("not implemented!", #function)
    }
    
    func changeFocus(_ direction: SelfRelativeDirection) {
        print("not implemented!", #function)
    }
}
