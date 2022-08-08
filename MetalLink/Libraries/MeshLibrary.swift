//
//  MeshLibrary.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 8/7/22.
//

import MetalKit

enum MeshType {
    case Triangle_Custom
}

class MeshLibrary: LockingCache<MeshType, MetalLinkMesh> {
    let link: MetalLink
    
    init(_ link: MetalLink) {
        self.link = link
    }
    
    override func make(_ key: Key, _ store: inout [Key : Value]) -> Value {
        switch key {
        case .Triangle_Custom:
            return try! MetalLinkTriangleMesh(link)
        }
    }
}
