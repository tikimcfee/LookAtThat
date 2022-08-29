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
//        try setupSnapTestMono()

        // TODO: ManyGrid need more abstractions
//        try setupSnapTestMonoMuchDataManyGrid()
        
        try setupSnapTestMulti()
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
            
            let nextRow: WorldGridEditor.AddStyle = .inNextRow(consumer.targetGrid)
            let nextPlane: WorldGridEditor.AddStyle = .inNextPlane(consumer.targetGrid)
            let trailing: WorldGridEditor.AddStyle = .trailingFromLastGrid(consumer.targetGrid)
            
//            let random = Bool.random() ? nextRow : Bool.random() ? nextPlane : trailing
//            editor.transformedByAdding(random)
//            editor.transformedByAdding(trailing)
            
            if files % 11 == 0 {
                editor.transformedByAdding(nextRow)
            } else if files % 51 == 0 {
                editor.transformedByAdding(nextPlane)
            } else {
                editor.transformedByAdding(trailing)
            }
            
            files += 1
            attachPickingStream(to: consumer.targetCollection)
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
        
        func doEditorAdd(_ childPath: URL) {
            let consumer = builder.createConsumerForNewGrid()
            consumer.consume(url: childPath)
            rootCollection.updateModelConstants()
            editor.transformedByAdding(.trailingFromLastGrid(consumer.targetGrid))
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
        
        // TODO: see other comments about nodes updating buffer directly
        // Manually update to push index mapping update.
        firstConsumer.targetCollection.updateModelConstants()
        secondConsumer.targetCollection.updateModelConstants()
        
        func loop() {
            firstConsumer.targetGrid.updateAllNodeConstants { node, constant in
                constant.modelMatrix.rotateAbout(axis: Z_AXIS, by: Float.pi / 180)
                return constant
            }
            
            secondConsumer.targetGrid.updateAllNodeConstants { node, constant in
//                constant.modelMatrix.rotateAbout(axis: Y_AXIS, by: Float.pi / 90)
                constant.modelMatrix.translate(vector: LFloat3(x: cos(root.constants.totalTotalGameTime), y: 0, z: 0))
                return constant
            }
            
            DispatchQueue.global().asyncAfter(
                deadline: .now() + .milliseconds(33),
                execute: loop
            )
        }
        
        attachPickingStream(to: rootCollection)
        loop()
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
            _ = collection.addGlyph(
                GlyphCacheKey(source: symbol, .red)
            )
        }
        collection.setRootMesh()
    }
}
