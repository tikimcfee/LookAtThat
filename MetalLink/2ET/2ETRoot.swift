//
//  TriangleShape.swift
//  MetalSimpleInstancing
//
//  Created by Ivan Lugo on 8/6/22.
//  Copyright © 2022 Metal by Example. All rights reserved.
//

import Combine
import MetalKit
import SwiftUI
import SwiftSyntaxParser
import SwiftSyntax

class TwoETimeRoot: MetalLinkReader {
    let link: MetalLink
    
    lazy var camera = DebugCamera(link: link)
    lazy var root = RootNode(camera)
    var bag = Set<AnyCancellable>()
    
    var lastID: InstanceIDType = UInt.zero
    var lastGrid: CodeGrid?
    var lastSyntaxID: SyntaxIdentifier? = nil
    
    lazy var builder = try! CodeGridGlyphCollectionBuilder(
        link: link,
        sharedSemanticMap: GlobalInstances.gridStore.semanticMap,
        sharedTokenCache: GlobalInstances.gridStore.tokenCache,
        sharedGridCache: GlobalInstances.gridStore.gridCache
    )
    
    init(link: MetalLink) throws {
        self.link = link
        view.clearColor = MTLClearColorMake(0.03, 0.1, 0.2, 1.0)
        
        camera.interceptor.onNewFileOperation = handleDirectory
        
//        try setupNodeChildTest()
        try setupNodeBackgroundTest()
//        try setupBackgroundTest()
//        try setupSnapTestMulti()
        
         // TODO: ManyGrid need more abstractions
//        try setupSnapTestMonoMuchDataManyGrid()
    }
    
    func delegatedEncode(in sdp: inout SafeDrawPass) {
        let dT =  1.0 / Float(link.view.preferredFramesPerSecond)
        
        // TODO: Create a proper container for all this glyph parent stuff.
        // Collection, builder, consumer, writer, grid... lol.
        // One more can't hurt.
        sdp.renderCommandEncoder.setVertexBuffer(builder.parentBuffer.buffer, offset: 0, index: 3)
        
        // TODO: Make update and render a single pass to avoid repeated child loops
        root.update(deltaTime: dT)
        root.render(in: &sdp)
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
    
    func basicGridPipeline(_ childPath: URL) -> GlyphCollectionSyntaxConsumer {
        let consumer = builder.createConsumerForNewGrid()
        consumer.consume(url: childPath)
        consumer.targetGrid.fileName = childPath.fileName
        
        GlobalInstances.gridStore.semanticsController
            .attachPickingStream(to: consumer.targetGrid)
        
        return consumer
    }
    
    func basicAddPipeline(_ action: @escaping (URL) -> Void) {
        GlobalInstances.fileBrowser.$fileSelectionEvents.sink { event in
            switch event {
            case let .newMultiCommandRecursiveAllLayout(rootPath, _):
                FileBrowser.recursivePaths(rootPath)
                    .filter { !$0.isDirectory }
                    .forEach { childPath in
                        action(childPath)
                    }
                
            case let .newSingleCommand(url, _):
                action(url)
                
            default:
                break
            }
        }.store(in: &bag)
    }
}

enum MetalGlyphError: String, Error {
    case noBitmaps
    case noTextures
    case noMesh
    case noAtlasTexture
}

class BackgroundQuad: MetalLinkObject, ContentSizing {
    let quad: MetalLinkQuadMesh
    
    var contentWidth: Float { quad.width }
    var contentHeight: Float { quad.height }
    var contentDepth: Float { 1 }
    var offset: LFloat3 {
        LFloat3(-contentWidth / 2.0, contentHeight / 2.0, 0)
    }
    
    init(_ link: MetalLink) {
        self.quad = MetalLinkQuadMesh(link)
        super.init(link, mesh: quad)
    }
}

extension TwoETimeRoot {
    func setupNodeChildTest() throws {
        let origin = BackgroundQuad(link)
        origin.quad.height = 1
        origin.quad.width = 1
        origin.setColor(LFloat4(1, 0, 0, 1))
        
        let firstparent = BackgroundQuad(link)
        firstparent.quad.height = 1
        firstparent.quad.width = 1
        firstparent.setColor(LFloat4(0, 1, 0, 1))
        
        let firstChild = BackgroundQuad(link)
        firstChild.quad.height = 1
        firstChild.quad.width = 1
        firstChild.setColor(LFloat4(0, 0, 1, 1))
        
        root.add(child: origin)
        origin.add(child: firstparent)
        firstparent.add(child: firstChild)
        
        firstparent.position = LFloat3(2, 0, -1)
        firstChild.position = LFloat3(2, 0, 0)
        
        var counter = 0.1
        QuickLooper(interval: .milliseconds(30)) {
            firstparent.position.x = cos(counter).float
            firstparent.scale = LFloat3(cos(counter).float, 1, 1)
            counter += 0.1
        }.runUntil { false }
    }
    
    func setupNodeBackgroundTest() throws {
        builder.mode = .multiCollection // TODO: DO NOT switch to mono without render breakpoints. crazy memory leak / performance issue with many grids
        let editor = WorldGridEditor()
        
        func doAdd(_ consumer: GlyphCollectionSyntaxConsumer) {
            let background = BackgroundQuad(link)
            background.quad.height = consumer.targetGrid.boundsHeight
            background.quad.width = consumer.targetGrid.boundsWidth
            
            root.add(child: consumer.targetCollection)
            consumer.targetCollection.add(child: background)
            
            editor.transformedByAdding(.trailingFromLastGrid(consumer.targetGrid))
            
            background.position = background.position.translated(
                dX: background.lengthX / 2.0,
                dY: -background.lengthY / 2.0,
                dZ: -1.0
            )
            
//            // TODO: < 30ms updates gives us flickering because of.. rendering order maybe?
//            QuickLooper(interval: .milliseconds(30)) {
//                consumer.targetCollection.rotation.y += 0.1
//            }.runUntil { false }
            
            GlobalInstances.gridStore.semanticsController
                .attachPickingStream(to: consumer.targetGrid)
        }
        
        basicAddPipeline { filePath in
            doAdd(self.basicGridPipeline(filePath))
        }
    }
    
    func setupBackgroundTest() throws {
        let background = BackgroundQuad(link)
        background.position = LFloat3(0.0, 0.0, -50.0)
        background.setColor(LFloat4(1.0, 0.0, 0.0, 1.0))
        background.quad.height = 3.0
        
        let background2 = BackgroundQuad(link)
        background2.position = LFloat3(4.0, 0.0, -50.0)
        background2.setColor(LFloat4(0.0, 1.0, 0.0, 1.0))
        background2.quad.height = 7.0
        
        let background3 = BackgroundQuad(link)
        background3.position = LFloat3(8.0, 0.0, -50.0)
        background3.setColor(LFloat4(0.0, 0.0, 1.0, 1.0))
        
        print(background.centerPosition)
        print(background2.centerPosition)
        print(background3.centerPosition)
        
        root.add(child: background)
        root.add(child: background2)
        root.add(child: background3)
        
        background2.setLeading(background.trailing)
        background2.setTop(background.top)
        background3.setLeading(background2.trailing)
        background3.setTop(background2.top)
        
        print(background.centerPosition)
        print(background2.centerPosition)
        print(background3.centerPosition)
    }
    
    func setupSnapTestMulti() throws {
        // TODO: make switching between multi/mono better
        // multi needs to add each collection; mono needs to add root
        builder.mode = .multiCollection
        
        let rootCollection = builder.getCollection()
        root.add(child: rootCollection)
        root.scale = LFloat3(0.25, 0.25, 0.25)
        root.position.z -= 30
        
        let editor = WorldGridEditor()
        
        var files = 1
        func doEditorAdd(_ childPath: URL) {
            let consumer = builder.createConsumerForNewGrid()
            consumer.targetCollection.position.z -= 30
            root.add(child: consumer.targetCollection)
            
            consumer.consume(url: childPath)
            consumer.targetGrid.fileName = childPath.fileName
        
            let nextRow: WorldGridEditor.AddStyle = .inNextRow(consumer.targetGrid)
            let nextPlane: WorldGridEditor.AddStyle = .inNextPlane(consumer.targetGrid)
            let trailing: WorldGridEditor.AddStyle = .trailingFromLastGrid(consumer.targetGrid)
            
            if files % 11 == 0 {
                editor.transformedByAdding(nextRow)
            } else if files % (75) == 0 {
                editor.transformedByAdding(nextPlane)
            } else {
                editor.transformedByAdding(trailing)
            }
            
            files += 1
            GlobalInstances.gridStore.semanticsController
                .attachPickingStream(to: consumer.targetGrid)
        }
        
        GlobalInstances.fileBrowser.$fileSelectionEvents.sink { event in
            switch event {
            case let .newMultiCommandRecursiveAllLayout(rootPath, _):
                FileBrowser.recursivePaths(rootPath)
                    .filter { !$0.isDirectory }
                    .forEach { childPath in
                        doEditorAdd(childPath)
                    }
                
            case let .newSingleCommand(url, _):
                doEditorAdd(url)
                
            default:
                break
            }
        }.store(in: &bag)
    }
    
    // TODO: This is going to be complicated.
    // I will try to update the SyntaxConsumer and GlyphCollection
    // to have some kind of child grid relationship.
    // Maybe a subclass of GlyphCollection that is MultiGridCollection.
    // If I do this, the child grids will have to update the parent buffer
    // somehow, without making duplicates.
    // Maybe avoiding the draw calls isn't important for now? ...
    func setupSnapTestMonoMuchDataManyGrid() throws {
        builder.mode = .monoCollection
        
        let rootCollection = builder.getCollection()
        rootCollection.scale = LFloat3(0.5, 0.5, 0.5)
        rootCollection.position.z -= 30
        root.add(child: rootCollection)
        
        let editor = WorldGridEditor()
        editor.layoutStrategy = .collection(target: rootCollection)
        
        var isFirst = true
        func doEditorAdd(_ childPath: URL) {
            let consumer = builder.createConsumerForNewGrid()
            consumer.consume(url: childPath)
            
            editor.transformedByAdding(.trailingFromLastGrid(consumer.targetGrid))
            guard isFirst else { return }
            isFirst = false
            
            var time = Float(0.0)
            func testAnimation() {
                DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(30)) {
                    time += 30
                    consumer.targetGrid.position += LFloat3(cos(time / 1000), 0, 0)
                    testAnimation()
                }
            }
            testAnimation()
        }
        
        GlobalInstances.fileBrowser.$fileSelectionEvents.sink { event in
            switch event {
            case let .newMultiCommandRecursiveAllLayout(rootPath, _):
                FileBrowser.recursivePaths(rootPath)
                    .filter { !$0.isDirectory }
                    .forEach { childPath in
                        doEditorAdd(childPath)
                    }
                
            case let .newSingleCommand(url, _):
                doEditorAdd(url)
                
            default:
                break
            }
        }.store(in: &bag)
    }
}
