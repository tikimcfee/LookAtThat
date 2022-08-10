//
//  MeshLibrary.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 8/7/22.
//

import MetalKit

enum MeshType {
    case Triangle
    case Quad
    case Cube
}

class MeshLibrary: LockingCache<MeshType, MetalLinkMesh> {
    let link: MetalLink
    
    init(_ link: MetalLink) {
        self.link = link
    }
    
    override func make(_ key: Key, _ store: inout [Key : Value]) -> Value {
        switch key {
        case .Triangle:
            return try! MetalLinkTriangleMesh(link)
        case .Quad:
            return try! MetalLinkQuadMesh(link)
        case .Cube:
            return try! MetalLinkCubeMesh(link)
        }
    }
}

extension MeshLibrary {
    func makeObject(_ type: MeshType) throws -> MetalLinkObject {
        try MetalLinkObject(link, mesh: self[type])
    }
}
