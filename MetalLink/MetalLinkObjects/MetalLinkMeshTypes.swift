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
    var topLeft: Vertex {
        get { vertices[1] }
        set { vertices[1] = newValue }
    }
    
    var topRight: Vertex {
        get { vertices[0] }
        set { vertices[0] = newValue; vertices[3] = newValue }
    }
    
    var bottomLeft: Vertex {
        get { vertices[2] }
        set { vertices[2] = newValue; vertices[4] = newValue }
    }
    
    var bottomRight: Vertex {
        get { vertices[5] }
        set { vertices[5] = newValue }
    }
    
    func applyUVsToInstance<T>(_ instance: inout MetalLinkInstancedObject<T>.InstancedConstants) {
        // Texture UV (left, top , width, height)
        //
        // topLeft = (left, top)
        // topRight = (left + width, top)
        // botLeft = (left, top + height)
        // botRight = (left + width, top + height)
        //
        instance.textureUV = LFloat4(
            topLeft.textureCoordinate.x,
            topLeft.textureCoordinate.y,
            topRight.textureCoordinate.x - topLeft.textureCoordinate.x,
            bottomRight.textureCoordinate.y - topRight.textureCoordinate.y
        )
    }
    
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
        
    func updateUVs(boundingBox: LFloat4) {
        let (left, top, width, height) = (boundingBox.x, boundingBox.y, boundingBox.z, boundingBox.w)
        topLeft.textureCoordinate = LFloat2(left, top)
        bottomLeft.textureCoordinate = LFloat2(left, top + height)
        topRight.textureCoordinate = LFloat2(left + width, top)
        bottomRight.textureCoordinate = LFloat2(left + width, top + height)
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
