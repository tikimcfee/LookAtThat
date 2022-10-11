//
//  MetalLinkMesh.swift
//  MetalSimpleInstancing
//
//  Created by Ivan Lugo on 8/7/22.
//  Copyright © 2022 Metal by Example. All rights reserved.
//

import MetalKit

protocol MetalLinkMesh {
    func getVertexBuffer() -> MTLBuffer?
    func deallocateVertexBuffer()  // TODO: Don't deallocate the entire buffer.. at least pool it... clear it?
    var vertexCount: Int { get }
    var vertices: [Vertex] { get set }
    var name: String { get }
}

class MetalLinkBaseMesh: MetalLinkMesh {
    private let link: MetalLink
    private var vertexBuffer: MTLBuffer?
    
    // Making this concurrent is sorta throwing up hands
    // to a lock on meshes, but I'm still testing.. is what
    // I'm telling myself.
    
    var vertices: [Vertex] {
        get { concurrenctVertices.values }
        set {
            concurrenctVertices.removeAll(keepingCapacity: true)
            newValue.forEach { concurrenctVertices.append($0) }
        }
    }
    var concurrenctVertices = ConcurrentArray<Vertex>()
    var vertexCount: Int { concurrenctVertices.count }
    var name: String { "BaseMesh" }

    init(_ link: MetalLink) {
        self.link = link
        createVertices().forEach {
            concurrenctVertices.append($0)
        }
    }
    
    func getVertexBuffer() -> MTLBuffer? {
        if let buffer = vertexBuffer { return buffer }
        concurrenctVertices.directWriteAccess {
            vertexBuffer = try? Self.createVertexBuffer(with: link, for: $0)
            vertexBuffer?.label = name
        }
        return vertexBuffer
    }
    
    func deallocateVertexBuffer() {
        vertexBuffer = nil
    }
    
    func createVertices() -> [Vertex] { [] }
}

private extension MetalLinkBaseMesh {
    static func createVertexBuffer(
        with link: MetalLink,
        for vertices: [Vertex]
    ) throws -> MTLBuffer {
        
        let memoryLength = vertices.count * Vertex.memStride
        
        guard let buffer = link.device.makeBuffer(
            bytes: vertices, length: memoryLength,
            options: []
        ) else {
            throw CoreError.noBufferAvailable
        }
        
        return buffer
    }
}

