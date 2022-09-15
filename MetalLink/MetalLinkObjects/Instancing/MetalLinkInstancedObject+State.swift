//
//  MetalLinkInstancedObject+State.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 8/21/22.
//

import Foundation
import Metal

class InstanceState<InstancedNodeType> {
    let link: MetalLink
    
    private(set) var parentCache = Cached<MTLBuffer?>(current: nil, update: { nil })
    
    var virtualParents: [MetalLinkNode] = [] { didSet { parentCache.dirty() }}
    var nodes: [InstancedNodeType] = []
    
    private let constants: BackingBuffer<InstancedConstants>
    private(set) var instanceIdNodeLookup = ConcurrentDictionary<UInt, InstancedNodeType>()
    
    var instanceBufferCount: Int { constants.currentEndIndex }
    var instanceBuffer: MTLBuffer { constants.buffer }
    var rawPointer: UnsafeMutablePointer<InstancedConstants> {
        get { constants.pointer }
        set { constants.pointer = newValue }
    }
    
    init(link: MetalLink) throws {
        self.link = link
        self.constants = try BackingBuffer(link: link)
        self.parentCache.update = makeParentsBuffer
    }
    
    func indexValid(_ index: Int) -> Bool {
        return index >= 0
            && index < instanceBufferCount
    }
    
    private func makeConstants() throws -> InstancedConstants {
        let newConstants = try constants.createNext {
            $0.instanceID = InstanceCounter.shared.nextId(.generic) // TODO: generic is bad, be specific or change enum thing
        }
        return newConstants
    }
    
    func makeAndUpdateConstants(_ operation: (inout InstancedConstants) -> Void) throws {
        var newConstants = try makeConstants()
        operation(&newConstants)
        rawPointer[newConstants.arrayIndex] = newConstants
    }
    
    // Appends info and returns last index
    func appendToState(node newNode: InstancedNodeType) {
        nodes.append(newNode)
    }
    
    private func makeParentsBuffer() -> MTLBuffer? {
        print("Creating buffer for parent constants: \(self.virtualParents.count)")
        do {
            if self.virtualParents.count == 0 {
                print("\n\n\tAttempting to create empty buffer!")
            }
            let safeCount = max(1, self.virtualParents.count)
            return try link.makeBuffer(of: ParentConstants.self, count: safeCount)
        } catch {
            print(error)
            return nil
        }
    }
    
    typealias BufferOperator = (
        InstancedNodeType,
        InstancedConstants,
        UnsafeMutablePointer<InstancedConstants>
    ) -> Void
    
    func zipUpdate(_ nodeUpdateFunction: BufferOperator)  {
//        guard bufferCache.willRebuild else {
//            return
//        }
        
        var pointerCopy = rawPointer
        zip(nodes, constants).forEach { node, constant in
            nodeUpdateFunction(node, constant, pointerCopy)
            pointerCopy = pointerCopy.advanced(by: 1)
        }
    }

}
