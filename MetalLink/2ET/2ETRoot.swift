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

class TwoETimeRoot: MetalLinkReader {
    let link: MetalLink
    
    lazy var camera = DebugCamera(link: link)
    lazy var root = RootNode(camera)
    var bag = Set<AnyCancellable>()
    
    var lastID = UInt.zero
    var lastCollection: GlyphCollection?
    
    lazy var builder = CodeGridGlyphCollectionBuilder(link: link)
    
    init(link: MetalLink) throws {
        self.link = link
        
        view.clearColor = MTLClearColorMake(0.03, 0.1, 0.2, 1.0)
//        try testMultiCollection()
//        try testMonoCollection()
//        try setupSnapTest()
        try setupSnapTestMono()
        
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
    func setupSnapTestMonoMuchDataManyGrid() throws {
        builder.mode = .monoCollection
        
        let rootCollection = builder.getCollection()
        rootCollection.scale = LFloat3(0.5, 0.5, 0.5)
        rootCollection.position.z -= 30
        root.add(child: rootCollection)
        
        GlobalInstances.fileBrowser.$fileSelectionEvents.sink { event in
            switch event {
            case let .newMultiCommandRecursiveAllLayout(rootPath, _):
                FileBrowser.recursivePaths(rootPath)
                    .filter { !$0.isDirectory }
                    .forEach { childPath in
                        self.builder
                            .createConsumerForNewGrid()
                            .consume(url: childPath)
                    }
                
            case let .newSingleCommand(url, _):
                self.builder
                    .createConsumerForNewGrid()
                    .consume(url: url)
                
            default:
                break
            }
        }.store(in: &bag)
    }
    
    func setupSnapTestMono() throws {
        builder.mode = .monoCollection
        
        let rootCollection = builder.getCollection()
        rootCollection.scale = LFloat3(0.5, 0.5, 0.5)
        rootCollection.position.z -= 30
        root.add(child: rootCollection)
        
        let firstConsumer = builder.createConsumerForNewGrid()
        let firstSource = """
        let x = 10
        let y = 15
        let sum = x + y
        print(sum)
        """
        let firstSyntax = try SyntaxParser.parse(source: firstSource)
        firstConsumer.consume(rootSyntaxNode: firstSyntax._syntaxNode)
        firstConsumer.targetCollection.renderer.pointer.away(30)
        firstConsumer.targetCollection.renderer.pointer.position.x = 0
        firstConsumer.targetCollection.renderer.pointer.position.y = 0
        
        let secondConsumer = builder.createConsumerForNewGrid()
        let secondSource = """
        if suggestions(of: yourFace.parameters).implies([.dork, .nerd, .geek, .spaz]) {
            do {
                try welcome(yourFace)
            } catch {
                print(error, "Well, you are still welcome here.")
            }
        }
        """
        let secondSyntax = try SyntaxParser.parse(source: secondSource)
        secondConsumer.consume(rootSyntaxNode: secondSyntax._syntaxNode)
        secondConsumer.targetCollection.renderer.pointer.away(30)
        firstConsumer.targetCollection.renderer.pointer.position.x = 0
        firstConsumer.targetCollection.renderer.pointer.position.y = 0
        
        // TODO: Editor works on rootNode.position, but mono collection uses internal pointer
        // DO something about the CodeGrid breaking the mono/multi setup.
        // Maybe hook up the WorldEditor to target collection pointers instead of root nodes?
//        let editor = WorldGridEditor()
//        editor.transformedByAdding(.trailingFromLastGrid(firstConsumer.targetGrid))
//        editor.transformedByAdding(.inNextPlane(secondConsumer.targetGrid))
    }
    
    func setupSnapTest() throws {
        // TODO: make switching between multi/mono better
        // multi needs to add each collection; mono needs to add root
        builder.mode = .multiCollection
        
        let rootCollection = builder.getCollection()
        root.add(child: rootCollection)
        root.scale = LFloat3(0.5, 0.5, 0.5)
        root.position.z -= 30
        
        let firstConsumer = builder.createConsumerForNewGrid()
        let firstSource = """
        let x = 10
        let y = 15
        let sum = x + y
        print(sum)
        """
        let firstSyntax = try SyntaxParser.parse(source: firstSource)
        firstConsumer.consume(rootSyntaxNode: firstSyntax._syntaxNode)
        firstConsumer.targetCollection.position.z -= 30
        root.add(child: firstConsumer.targetCollection)
        
        let secondConsumer = builder.createConsumerForNewGrid()
        let secondSource = """
        if suggestions(of: yourFace.parameters).implies([.dork, .nerd, .geek, .spaz]) {
            do {
                try welcome(yourFace)
            } catch {
                print(error, "Well, you are still welcome here.")
            }
        }
        """
        let secondSyntax = try SyntaxParser.parse(source: secondSource)
        secondConsumer.consume(rootSyntaxNode: secondSyntax._syntaxNode)
        secondConsumer.targetCollection.position.z -= 30
        root.add(child: secondConsumer.targetCollection)
        
        let editor = WorldGridEditor()
        editor.transformedByAdding(.trailingFromLastGrid(firstConsumer.targetGrid))
        editor.transformedByAdding(.inNextPlane(secondConsumer.targetGrid))
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
        builder.mode = .multiCollection
        var offset = LFloat3(-5, 0, -30)
        func addCollection(_ path: URL) {
            let consumer = builder.createConsumerForNewGrid()
            let grid = consumer.targetGrid
            let collection = grid.rootNode
            
            consumer.consume(url: path)
            
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
        builder.mode = .monoCollection
        let consumer = builder.createConsumerForNewGrid()
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
