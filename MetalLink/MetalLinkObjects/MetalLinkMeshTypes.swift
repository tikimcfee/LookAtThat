//
//  MetalLinkTriangleMesh.swift
//  MetalSimpleInstancing
//
//  Created by Ivan Lugo on 8/7/22.
//  Copyright © 2022 Metal by Example. All rights reserved.
//

import MetalKit

class MetalLinkTriangleMesh: MetalLinkBaseMesh {
    override func createVertices() -> [Vertex] { [
        Vertex(position: LFloat3( 0, 1, 0), color: LFloat4(1,0,0,1)),
        Vertex(position: LFloat3(-1,-1, 0), color: LFloat4(0,1,0,1)),
        Vertex(position: LFloat3( 1,-1, 0), color: LFloat4(0,0,1,1))
    ] }
}

class MetalLinkQuadMesh: MetalLinkBaseMesh {
    override func createVertices() -> [Vertex] { [
        Vertex(position: LFloat3( 1, 1, 0), color: LFloat4(1,0,0,1)),
        Vertex(position: LFloat3(-1, 1, 0), color: LFloat4(0,1,0,1)),
        Vertex(position: LFloat3(-1,-1, 0), color: LFloat4(0,0,1,1)),
        
        Vertex(position: LFloat3( 1, 1, 0), color: LFloat4(1,0,0,1)),
        Vertex(position: LFloat3(-1,-1, 0), color: LFloat4(0,0,1,1)),
        Vertex(position: LFloat3( 1,-1, 0), color: LFloat4(1,0,1,1))
    ] }
}

class MetalLinkCubeMesh: MetalLinkBaseMesh {
    override func createVertices() -> [Vertex] { [
        //Left
        Vertex(position: LFloat3(-1.0,-1.0,-1.0), color: LFloat4(1.0, 0.5, 0.0, 1.0)),
        Vertex(position: LFloat3(-1.0,-1.0, 1.0), color: LFloat4(0.0, 1.0, 0.5, 1.0)),
        Vertex(position: LFloat3(-1.0, 1.0, 1.0), color: LFloat4(0.0, 0.5, 1.0, 1.0)),
        Vertex(position: LFloat3(-1.0,-1.0,-1.0), color: LFloat4(1.0, 1.0, 0.0, 1.0)),
        Vertex(position: LFloat3(-1.0, 1.0, 1.0), color: LFloat4(0.0, 1.0, 1.0, 1.0)),
        Vertex(position: LFloat3(-1.0, 1.0,-1.0), color: LFloat4(1.0, 0.0, 1.0, 1.0)),
        
        //RIGHT
        Vertex(position: LFloat3( 1.0, 1.0, 1.0), color: LFloat4(1.0, 0.0, 0.5, 1.0)),
        Vertex(position: LFloat3( 1.0,-1.0,-1.0), color: LFloat4(0.0, 1.0, 0.0, 1.0)),
        Vertex(position: LFloat3( 1.0, 1.0,-1.0), color: LFloat4(0.0, 0.5, 1.0, 1.0)),
        Vertex(position: LFloat3( 1.0,-1.0,-1.0), color: LFloat4(1.0, 1.0, 0.0, 1.0)),
        Vertex(position: LFloat3( 1.0, 1.0, 1.0), color: LFloat4(0.0, 1.0, 1.0, 1.0)),
        Vertex(position: LFloat3( 1.0,-1.0, 1.0), color: LFloat4(1.0, 0.5, 1.0, 1.0)),
        
        //TOP
        Vertex(position: LFloat3( 1.0, 1.0, 1.0), color: LFloat4(1.0, 0.0, 0.0, 1.0)),
        Vertex(position: LFloat3( 1.0, 1.0,-1.0), color: LFloat4(0.0, 1.0, 0.0, 1.0)),
        Vertex(position: LFloat3(-1.0, 1.0,-1.0), color: LFloat4(0.0, 0.0, 1.0, 1.0)),
        Vertex(position: LFloat3( 1.0, 1.0, 1.0), color: LFloat4(1.0, 1.0, 0.0, 1.0)),
        Vertex(position: LFloat3(-1.0, 1.0,-1.0), color: LFloat4(0.5, 1.0, 1.0, 1.0)),
        Vertex(position: LFloat3(-1.0, 1.0, 1.0), color: LFloat4(1.0, 0.0, 1.0, 1.0)),
        
        //BOTTOM
        Vertex(position: LFloat3( 1.0,-1.0, 1.0), color: LFloat4(1.0, 0.5, 0.0, 1.0)),
        Vertex(position: LFloat3(-1.0,-1.0,-1.0), color: LFloat4(0.5, 1.0, 0.0, 1.0)),
        Vertex(position: LFloat3( 1.0,-1.0,-1.0), color: LFloat4(0.0, 0.0, 1.0, 1.0)),
        Vertex(position: LFloat3( 1.0,-1.0, 1.0), color: LFloat4(1.0, 1.0, 0.5, 1.0)),
        Vertex(position: LFloat3(-1.0,-1.0, 1.0), color: LFloat4(0.0, 1.0, 1.0, 1.0)),
        Vertex(position: LFloat3(-1.0,-1.0,-1.0), color: LFloat4(1.0, 0.5, 1.0, 1.0)),
        
        //BACK
        Vertex(position: LFloat3( 1.0, 1.0,-1.0), color: LFloat4(1.0, 0.5, 0.0, 1.0)),
        Vertex(position: LFloat3(-1.0,-1.0,-1.0), color: LFloat4(0.5, 1.0, 0.0, 1.0)),
        Vertex(position: LFloat3(-1.0, 1.0,-1.0), color: LFloat4(0.0, 0.0, 1.0, 1.0)),
        Vertex(position: LFloat3( 1.0, 1.0,-1.0), color: LFloat4(1.0, 1.0, 0.0, 1.0)),
        Vertex(position: LFloat3( 1.0,-1.0,-1.0), color: LFloat4(0.0, 1.0, 1.0, 1.0)),
        Vertex(position: LFloat3(-1.0,-1.0,-1.0), color: LFloat4(1.0, 0.5, 1.0, 1.0)),
        
        //FRONT
        Vertex(position: LFloat3(-1.0, 1.0, 1.0), color: LFloat4(1.0, 0.5, 0.0, 1.0)),
        Vertex(position: LFloat3(-1.0,-1.0, 1.0), color: LFloat4(0.0, 1.0, 0.0, 1.0)),
        Vertex(position: LFloat3( 1.0,-1.0, 1.0), color: LFloat4(0.5, 0.0, 1.0, 1.0)),
        Vertex(position: LFloat3( 1.0, 1.0, 1.0), color: LFloat4(1.0, 1.0, 0.5, 1.0)),
        Vertex(position: LFloat3(-1.0, 1.0, 1.0), color: LFloat4(0.0, 1.0, 1.0, 1.0)),
        Vertex(position: LFloat3( 1.0,-1.0, 1.0), color: LFloat4(1.0, 0.0, 1.0, 1.0))
    ] }
}
