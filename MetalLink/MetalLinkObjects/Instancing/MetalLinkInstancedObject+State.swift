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
        
    var nodes: [InstancedNodeType] = []
    
    private let constants: BackingBuffer<InstancedConstants>
    private(set) var instanceIdNodeLookup = ConcurrentDictionary<InstanceIDType, InstancedNodeType>()
    
    var instanceBufferCount: Int { constants.currentEndIndex }
    var instanceBuffer: MTLBuffer { constants.buffer }
    var rawPointer: UnsafeMutablePointer<InstancedConstants> {
        get { constants.pointer }
        set { constants.pointer = newValue }
    }
    
    init(
        link: MetalLink,
        bufferSize: Int = BackingBufferDefaultSize
    ) throws {
        self.link = link
        self.constants = try BackingBuffer(
            link: link,
            initialSize: bufferSize
        )
    }
    
    func indexValid(_ index: Int) -> Bool {
        return index >= 0
            && index < instanceBufferCount
    }
    
    private func makeConstants() throws -> InstancedConstants {
        let newConstants = try constants.createNext {
            $0.instanceID = InstanceCounter.shared.nextGlyphId() // TODO: generic is bad, be specific or change enum thing
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
