//
//  GlobalInstances.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 8/28/22.
//
// ------------------------------------------------------------------------------------
// I realize all this instance stuff is bad joojoo. Everything talks to everything else.
// However, I'm moving things around a lot right now and experimenting with placement and
// hierarchy. I'd rather have more concrete working stuff in place first.
// ------------------------------------------------------------------------------------
//
// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// A short term plan for this is, when things get dicey, to setup a 'getInstance(for: self)`
// intance locator that figure this stuff out. Or get a dependency locator library. Either's fine.
// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//

import Foundation
import Combine
import Metal

class GlobalInstances {
    private init () { }
}

// MARK: - App State
// ______________________________________________________________
extension GlobalInstances {
    static let appStatus = AppStatus()
    static let editorState = CodePagesPopupEditorState()
}


// MARK: - Files
// ______________________________________________________________
extension GlobalInstances {
    static let fileBrowser = FileBrowser()
    static let fileStream = fileBrowser.$scopes.share().eraseToAnyPublisher()
    static let fileEventStream = fileBrowser.$fileSelectionEvents.share().eraseToAnyPublisher()
}


// MARK: - Metal
// ______________________________________________________________
extension GlobalInstances {
    static let rootCustomMTKView: CustomMTKView = makeRootCustomMTKView()
    static let defaultLink: MetalLink = makeDefaultLink()
    static let defaultAtlas: MetalLinkAtlas = makeDefaultAtlas()
    
    private static func makeRootCustomMTKView() -> CustomMTKView {
        CustomMTKView(frame: .zero, device: MTLCreateSystemDefaultDevice())
    }
    
    private static func makeDefaultLink() -> MetalLink {
        return try! MetalLink(view: rootCustomMTKView)
    }
    
    private static func makeDefaultAtlas() -> MetalLinkAtlas {
        return try! MetalLinkAtlas(defaultLink)
    }
}


// MARK: - Grids
// ______________________________________________________________
extension GlobalInstances {
    static let gridStore = GridStore()
}


// MARK: - Shared Workers and caches
// ______________________________________________________________
class GridStore {
    private var link: MetalLink { GlobalInstances.defaultLink }
    private(set) lazy var semanticsController: MetalLinkSemanticsController = MetalLinkSemanticsController(link: link)
    private(set) lazy var tokenCache: CodeGridTokenCache = CodeGridTokenCache()
    private(set) lazy var semanticMap: SemanticInfoMap = SemanticInfoMap()
    
    private(set) lazy var gridCache: GridCache = GridCache(tokenCache: tokenCache)
    private(set) lazy var concurrentRenderer: ConcurrentGridRenderer = ConcurrentGridRenderer(cache: gridCache)
    private(set) lazy var globalSemantics: CodeGridGlobalSemantics = CodeGridGlobalSemantics(source: gridCache)
}
