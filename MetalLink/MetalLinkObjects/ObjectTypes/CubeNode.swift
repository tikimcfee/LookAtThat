//
//  CubeNode.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 8/9/22.
//

import MetalKit

class CubeNode: MetalLinkObject {
    init(link: MetalLink) throws {
        try super.init(link, mesh: link.meshes[.Cube])
    }
}
