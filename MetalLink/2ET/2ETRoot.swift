//
//  2ETRoot.swift
//  MetalSimpleInstancing
//
//  Created by Ivan Lugo on 8/6/22.
//  Copyright © 2022 Metal by Example. All rights reserved.
//
//  - With thanks to Rick Twohy
//  https://discord.gg/hKPBTbC
//

import Combine
import MetalKit
import SwiftUI
import SwiftParser
import SwiftSyntax

class TwoETimeRoot: MetalLinkReader {
    let link: MetalLink
    
    var bag = Set<AnyCancellable>()
    
    lazy var root = RootNode(camera)
    
    lazy var builder = try! CodeGridGlyphCollectionBuilder(
        link: link,
        sharedSemanticMap: GlobalInstances.gridStore.globalSemanticMap,
        sharedTokenCache: GlobalInstances.gridStore.globalTokenCache,
        sharedGridCache: GlobalInstances.gridStore.gridCache
    )
    
    var camera: DebugCamera {
        GlobalInstances.debugCamera
    }
    
    var editor: WorldGridEditor {
        GlobalInstances.gridStore.editor
    }
    
    var focus: WorldGridFocusController {
        GlobalInstances.gridStore.worldFocusController
    }
    
    init(link: MetalLink) throws {
        self.link = link
        view.clearColor = MTLClearColorMake(0.03, 0.1, 0.2, 1.0)
        
        camera.interceptor.onNewFileOperation = handleDirectory
        camera.interceptor.onNewFocusChange = handleFocus
        
        GlobalInstances
            .gridStore
            .gridInteractionState
            .setupStreams()
        
//        try setupNodeChildTest()
//        try setupNodeBackgroundTest()
//        try setupBackgroundTest()
//        try setupSnapTestMulti()
//        try setupTriangleStripTest()
        try setupWordWare()
        
         // TODO: ManyGrid need more abstractions
//        try setupSnapTestMonoMuchDataManyGrid()
    }
    
    func delegatedEncode(in sdp: inout SafeDrawPass) {
        let dT =  1.0 / Float(link.view.preferredFramesPerSecond)
        
        // TODO: Create a proper container for all this glyph parent stuff.
        // Collection, builder, consumer, writer, grid... lol.
        // One more can't hurt.
        sdp.renderCommandEncoder.setVertexBuffer(
            builder.parentBuffer.buffer,
            offset: 0,
            index: 3
        )
        
        // TODO: Make update and render a single pass to avoid repeated child loops
        root.update(deltaTime: dT)
        root.render(in: &sdp)
    }
    
    func handleFocus(_ direction: SelfRelativeDirection) {
        let focused = editor.lastFocusedGrid
        guard let current = focused else { return }
        
        let grids = editor.snapping.gridsRelativeTo(current, direction)
        
        if let first = grids.first {
            focus.state = .set(first.targetGrid)
        } else {
            focus.state = .set(current)
        }
    }
    
    func handleDirectory(_ file: FileOperation) {
        switch file {
        case .openDirectory:
            openDirectory { file in
                guard let url = file.parent else { return }
                GlobalInstances.fileBrowser.setRootScope(url)
            }
        }
    }
}

// MARK: - Current Test
class WordNode: MetalLinkNode {
    let glyphs: CodeGridNodes
    let parentGrid: CodeGrid
    
    init(
        glyphs: CodeGridNodes,
        parentGrid: CodeGrid
    ) {
        self.glyphs = glyphs
        self.parentGrid = parentGrid
        super.init()
        
        for glyph in glyphs {
            add(child: glyph)
        }
        modelEvents.sink { _ in
            parentGrid.pushNodes(glyphs)
        }.store(in: &eventBag)
    }
    
    func doOnAll(_ receiver: (CodeGridNodes) -> Void) {
        receiver(glyphs)
        parentGrid.pushNodes(glyphs)
    }
}

extension TwoETimeRoot {
    func setupWordWare() throws {
        let wordContainerGrid = builder.createGrid()
        wordContainerGrid.removeBackground()
        wordContainerGrid.translated(dZ: -50.0)
        
        var counter = 0.0
        let (_, nodes) = wordContainerGrid.consume(text: "Hello")
        let helloNode = WordNode(glyphs: nodes, parentGrid: wordContainerGrid)
//        root.add(child: helloNode)
        
        QuickLooper(interval: .milliseconds(16)) {
//            let vector = LFloat3(x: cos(counter.float), y: 0, z: 0)
//            helloNode.doOnAll { nodes in
//                for node in nodes {
//                    node.translate(dX: cos(counter.float))
//                }
//            }
            helloNode.translate(dX: cos(counter.float / 5.0.float))
            counter += 1.0
        }.runUntil { false }
        
//        root.bindAsVirtualParentOf(grid.rootNode)
        root.add(child: wordContainerGrid.rootNode)
    }
}
