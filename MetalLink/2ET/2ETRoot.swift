//
//  TriangleShape.swift
//  MetalSimpleInstancing
//
//  Created by Ivan Lugo on 8/6/22.
//  Copyright © 2022 Metal by Example. All rights reserved.
//

import Combine
import MetalKit

class TwoETimeRoot: MetalLinkReader {
    let link: MetalLink
    
    lazy var camera = DebugCamera(link: link)
    lazy var root = RootNode(camera)
    var bag = Set<AnyCancellable>()
    
    var lastID = UInt.zero
    var lastCollection: GlyphCollection?
    
    init(link: MetalLink) throws {
        self.link = link
        
        view.clearColor = MTLClearColorMake(0.03, 0.1, 0.2, 1.0)
//        try testMultiCollection()
        try testMonoCollection()
        
//        link.input.sharedMouse.sink { event in
//            collection.instanceState.bufferCache.dirty()
//            collection.rotation.y += event.deltaX.float / 5
//            collection.rotation.x += event.deltaY.float / 5
//        }.store(in: &bag)
    }
    
    func delegatedEncode(in sdp: inout SafeDrawPass) {
        let dT =  1.0 / Float(link.view.preferredFramesPerSecond)
        
        // TODO: Make update and render a single pass to avoid repeated child loops
        root.update(deltaTime: dT)
        root.render(in: &sdp)
    }
}

enum MetalGlyphError: String, Error {
    case noBitmaps
    case noTextures
    case noMesh
    case noAtlasTexture
}

extension TwoETimeRoot {
    func setupSnapTest() throws {
        
    }
}

struct CodeGridGlyphCollectionBuilder {
    let link: MetalLink
    let atlas: MetalLinkAtlas
    let semanticMap: CodeGridSemanticMap
    let tokenCache: CodeGridTokenCache
    
    init(
        link: MetalLink,
        sharedSemanticMap semanticMap: CodeGridSemanticMap = .init(),
        sharedTokenCache tokenCache: CodeGridTokenCache = .init()
    ) {
        self.link = link
        self.atlas = GlobalInstances.defaultAtlas
        self.semanticMap = semanticMap
        self.tokenCache = tokenCache
    }
    
    func createCollection() -> GlyphCollection {
        GlyphCollection(link: link, linkAtlas: atlas)
    }
    
    func createGrid() -> CodeGrid {
        CodeGrid(rootNode: createCollection(), tokenCache: tokenCache)
    }
    
    func createSyntaxConsumer() -> GlyphCollectionSyntaxConsumer {
        GlyphCollectionSyntaxConsumer(targetGrid: createGrid())
    }
}

extension TwoETimeRoot {
    func attachPickingStream(to collection: GlyphCollection) {
        link.pickingTexture.sharedPickingHover.sink { glyphID in
            guard let constants = collection.instanceState.getConstantsPointer(),
                  let index = collection.instanceCache.findConstantIndex(for: glyphID)
            else { return }
            
            if let lastCollection = self.lastCollection,
               let lastPointer = lastCollection.instanceState.getConstantsPointer(),
               let lastIndex = lastCollection.instanceCache.findConstantIndex(for: self.lastID) {
                lastPointer[lastIndex].addedColor = .zero
            }
            
            self.lastID = glyphID
            self.lastCollection = collection
            
            constants[index].addedColor = LFloat4(0.3, 0.3, 0.3, 0)
            
        }.store(in: &bag)
    }
    
    func testMultiCollection() throws {
        let builder = CodeGridGlyphCollectionBuilder(link: link)
        
        var offset = LFloat3(-5, 0, -30)
        func addCollection(_ path: URL) {
            let consumer = builder.createSyntaxConsumer()
            let grid = consumer.targetGrid
            let collection = grid.rootNode
            
            consumer.consume(url: path)
            collection.setRootMesh()
            
            collection.scale = LFloat3(0.5, 0.5, 0.5)
            collection.position += offset
            offset.z -= 30
            
            root.add(child: collection)
            
            attachPickingStream(to: collection)
        }
        
        GlobalInstances.fileBrowser.$fileSelectionEvents.sink { event in
            switch event {
            case let .newMultiCommandRecursiveAllLayout(rootPath, _):
                FileBrowser.recursivePaths(rootPath)
                    .filter { !$0.isDirectory }
                    .forEach { childPath in
                        addCollection(childPath)
                    }
                
            case let .newSingleCommand(url, _):
                addCollection(url)
                
            default:
                break
            }
        }.store(in: &bag)
    }
    
    func testMonoCollection() throws {
        let builder = CodeGridGlyphCollectionBuilder(link: link)
        let consumer = builder.createSyntaxConsumer()
        let grid = consumer.targetGrid
        let collection = grid.rootNode
        collection.scale = LFloat3(0.5, 0.5, 0.5)
        collection.position.x = -25
        collection.position.y = 0
        collection.position.z = -30
        root.add(child: collection)
        
        func doConsume(_ url: URL) {
            consumer.consume(url: url)
            
            collection.renderer.pointer.position.x = 0
            collection.renderer.pointer.position.y = 0
            collection.renderer.pointer.away(50.0)
            
            collection.setRootMesh()
        }
        
        GlobalInstances.fileEventStream.sink { event in
            switch event {
            case let .newMultiCommandRecursiveAllLayout(rootPath, _):
                FileBrowser.recursivePaths(rootPath)
                    .filter { !$0.isDirectory }
                    .forEach { childPath in
                        doConsume(childPath)
                    }
                
            case let .newSingleCommand(url, _):
                doConsume(url)
                
            default:
                break
            }
        }.store(in: &bag)
        
        attachPickingStream(to: collection)
    }
    
    func setup11() throws {
        let atlas = GlobalInstances.defaultAtlas
        let collection = GlyphCollection(link: link, linkAtlas: atlas)
        collection.scale = LFloat3(0.5, 0.5, 0.5)
        collection.position.x = -25
        collection.position.y = 0
        collection.position.z = -30
        root.add(child: collection)
        
        let test = """
        Hello, Metal.
        This is some text.
        And you're rendering it just fine.
        """
        
        test.forEach { symbol in
            _ = collection.addGlyph(GlyphCacheKey(source: symbol, .red))
        }
        collection.setRootMesh()
    }
}
