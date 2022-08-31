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
