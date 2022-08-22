//
//  MetalLinkInstancedObject+State.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 8/21/22.
//

import Foundation
import Metal

extension MetalLinkInstancedObject {
    class InstanceState {
        let link: MetalLink
        
        private(set) var bufferCache: Cached<MTLBuffer?>
        var nodes: [InstancedNodeType] = [] { didSet { bufferCache.dirty() } }
        var constants: [InstancedConstants] = [] { didSet { bufferCache.dirty() } }
        
        init(link: MetalLink) {
            self.link = link
            // TODO: This is bad API. Why am I doing this?
            self.bufferCache = Cached(current: nil, update: { nil })
            self.bufferCache.update = makeBuffer
        }
        
        func refreshState(with nodes: [InstancedNodeType]) {
            self.nodes = nodes
            self.constants = nodes.map { _ in InstancedConstants() }
        }
        
        typealias BufferOperator = (
            InstancedNodeType,
            InstancedConstants,
            UnsafeMutablePointer<InstancedConstants>
        ) -> Void
        
        func zipUpdate(_ nodeUpdateFunction: BufferOperator)  {
            guard bufferCache.rebuildModel else {
                return
            }
            
            guard var pointer = getConstantsPointer() else {
                return
            }
            
            zip(nodes, constants).forEach { node, constant in
                nodeUpdateFunction(node, constant, pointer)
                pointer = pointer.advanced(by: 1)
            }
        }
        
        func getConstantsPointer() -> UnsafeMutablePointer<InstancedConstants>? {
            bufferCache.get()?
                .boundPointer(as: InstancedConstants.self, count: constants.count)
        }
        
        private func makeBuffer() -> MTLBuffer? {
            print("Creating buffer for instanced constants: \(self.constants.count)")
            do {
                return try link.makeBuffer(of: InstancedConstants.self, count: self.constants.count)
            } catch {
                print(error)
                return nil
            }
        }
    }
}
