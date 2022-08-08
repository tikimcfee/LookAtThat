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
    var vertexCount: Int { get }
}

class MetalLinkBaseMesh: MetalLinkMesh {
    private let link: MetalLink
    private var vertexBuffer: MTLBuffer?
    
    var vertexCount: Int { currentVertices.count }
    var currentVertices: [Vertex] = []

    init(_ link: MetalLink) throws {
        self.link = link
        self.currentVertices = createVertices()
    }
    
    func getVertexBuffer() -> MTLBuffer? {
        if let buffer = vertexBuffer { return buffer }
        vertexBuffer = try? Self.createVertexBuffer(with: link, for: currentVertices)
        return vertexBuffer
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

