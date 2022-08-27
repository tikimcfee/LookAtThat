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
    
    var lastId = InstanceIDType.zero
    
    init(link: MetalLink) throws {
        self.link = link
        
        view.clearColor = MTLClearColorMake(0.03, 0.1, 0.2, 1.0)
        try setup12()
        
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
    func setup13() throws {
        let atlas = try MetalLinkAtlas(link)
        let testMap = CodeGridSemanticMap()
        let testTokens = CodeGridTokenCache()
        
        var z: Float = -30.0
        func addCollection(_ path: URL) {
            let collection = GlyphCollection(link: link, linkAtlas: atlas)
            let grid = CodeGrid(rootNode: collection, tokenCache: testTokens)
            let consumer = GlyphCollectionSyntaxConsumer(
                targetCollection: collection,
                targetGrid: grid
            )
            
            consumer.consume(url: path)
            collection.setRootMesh()
            
            collection.scale = LFloat3(0.5, 0.5, 0.5)
            collection.position.x = -25
            collection.position.y = 0
            collection.position.z = z
            z -= 10
            
            root.add(child: collection)
        }
        
        GlobalInstances
            .fileBrowser
            .$fileSelectionEvents.sink { event in
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
    
    func setup12() throws {
        let atlas = try MetalLinkAtlas(link)
        let collection = GlyphCollection(link: link, linkAtlas: atlas)
        collection.scale = LFloat3(0.5, 0.5, 0.5)
        collection.position.x = -25
        collection.position.y = 0
        collection.position.z = -30
        root.add(child: collection)
        
        let testMap = CodeGridSemanticMap()
        let testTokens = CodeGridTokenCache()
        
        let grid = CodeGrid(rootNode: collection, tokenCache: testTokens)
        let consumer = GlyphCollectionSyntaxConsumer(
            targetCollection: collection,
            targetGrid: grid
        )
        
        func consume(_ url: URL) {
            consumer.consume(url: url)
            
            collection.renderer.pointer.position.x = 0
            collection.renderer.pointer.position.y = 0
            collection.renderer.pointer.away(50.0)
            
            collection.setRootMesh()
        }
        
        GlobalInstances
            .fileEventStream
            .sink { event in
                switch event {
                case let .newMultiCommandRecursiveAllLayout(rootPath, _):
                    FileBrowser.recursivePaths(rootPath)
                        .filter { !$0.isDirectory }
                        .forEach { childPath in
                            consume(childPath)
                        }
                    
                case let .newSingleCommand(url, _):
                    consume(url)
                    
                default:
                    break
                }
            }.store(in: &bag)
        
        link.pickingTexture.sharedPickingHover.sink { glyphID in
            guard let constants = collection.instanceState.getConstantsPointer(),
                  let index = collection.instanceCache.findConstantIndex(for: glyphID)
            else { return }
            
            if let oldIndex = collection.instanceCache.findConstantIndex(for: self.lastId) {
                constants[oldIndex].addedColor = .zero
            }
            self.lastId = glyphID
            
            constants[index].addedColor = LFloat4(0.3, 0.3, 0.3, 0)
            
        }.store(in: &bag)
    }
    
    func setup11() throws {
        let atlas = try MetalLinkAtlas(link)
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
            collection.addGlyph(GlyphCacheKey(source: symbol, .red))
        }
        collection.setRootMesh()
    }
}
