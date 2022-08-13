//
//  MetalLinkTriangleMesh.swift
//  MetalSimpleInstancing
//
//  Created by Ivan Lugo on 8/7/22.
//  Copyright © 2022 Metal by Example. All rights reserved.
//

import MetalKit

extension MetalLinkBaseMesh {
    func addVertex(
        position: LFloat3,
        color: LFloat4,
        textureCoordinate: LFloat2
    ) {
        vertices.append(Vertex(
            position: position,
            color: color,
            textureCoordinate: textureCoordinate)
        )
    }
}

class MetalLinkTriangleMesh: MetalLinkBaseMesh {
    override var name: String { "MLTriangle" }
    override func createVertices() -> [Vertex] { [
        Vertex(position: LFloat3( 0, 1, 0), color: LFloat4(1,0,0,1)),
        Vertex(position: LFloat3(-1,-1, 0), color: LFloat4(0,1,0,1)),
        Vertex(position: LFloat3( 1,-1, 0), color: LFloat4(0,0,1,1))
    ] }
}

class MetalLinkQuadMesh: MetalLinkBaseMesh {
    override var name: String { "MLQuad" }
    var width: Float {
        get { abs(vertices[0].position.x - vertices[1].position.x) }
        set {
            let width = newValue / 2.0
            vertices[1].position.x = -width
            vertices[2].position.x = -width
            vertices[4].position.x = -width
            vertices[0].position.x = width
            vertices[3].position.x = width
            vertices[5].position.x = width
        }
    }
    
    var height: Float {
        get { abs(vertices[1].position.y - vertices[2].position.y) }
        set {
            let height = newValue / 2.0
            vertices[0].position.y = height
            vertices[1].position.y = height
            vertices[3].position.y = height
            vertices[2].position.y = -height
            vertices[4].position.y = -height
            vertices[5].position.y = -height
        }
    }
    
    override func createVertices() -> [Vertex] { [
        Vertex(position: LFloat3( 1, 1, 0), color: LFloat4(1,0,0,1), textureCoordinate: LFloat2(1, 0)), /* T R 0 */
        Vertex(position: LFloat3(-1, 1, 0), color: LFloat4(0,1,0,1), textureCoordinate: LFloat2(0, 0)), /* T L 1 */
        Vertex(position: LFloat3(-1,-1, 0), color: LFloat4(0,0,1,1), textureCoordinate: LFloat2(0, 1)), /* B L 2 */
        Vertex(position: LFloat3( 1, 1, 0), color: LFloat4(1,0,0,1), textureCoordinate: LFloat2(1, 0)), /* T R 3 */
        Vertex(position: LFloat3(-1,-1, 0), color: LFloat4(0,0,1,1), textureCoordinate: LFloat2(0, 1)), /* B L 4 */
        Vertex(position: LFloat3( 1,-1, 0), color: LFloat4(1,0,1,1), textureCoordinate: LFloat2(1, 1))  /* B R 5 */
    ] }
    
    func updateUVs(
        topRight: LFloat2? = nil,
        topLeft: LFloat2? = nil,
        bottomLeft: LFloat2? = nil,
        bottomRight: LFloat2? = nil
    ) {
        if let topRight = topRight {
            vertices[0].textureCoordinate = topRight
            vertices[3].textureCoordinate = topRight
        }
        
        if let topLeft = topLeft {
            vertices[1].textureCoordinate = topLeft
        }
        
        if let bottomLeft = bottomLeft {
            vertices[2].textureCoordinate = bottomLeft
            vertices[4].textureCoordinate = bottomLeft
        }
        
        if let bottomRight = bottomRight {
            vertices[5].textureCoordinate = bottomRight
        }
    }
}

class MetalLinkCubeMesh: MetalLinkBaseMesh {
    override var name: String { "MLCube" }
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
