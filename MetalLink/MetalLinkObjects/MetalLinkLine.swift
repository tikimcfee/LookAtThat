//
//  MetalLinkLine.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 10/10/22.
//

import MetalKit

class MetalLinkLineMesh: MetalLinkBaseMesh {
    var width = 1.0.float; var halfWidth: Float { width / 2.0 }
    var height = 1.0.float; var halfHeight: Float { height / 2.0 }
    
    override var name: String { "MetalLinkLineMesh" }
    override func createVertices() -> [Vertex] { [] }
    
    // TODO: All segments imply an origin position for the line.
    // No line offsetting here; drop the line at the origin and set the vertices
    // to parent's space to get the desired effect. If there's a hiearchy... do the math.
    func addSegment(at point: LFloat3) {
        vertices.append(contentsOf: constructSegment(around: point))
    }
    
    func popSegment() {
        vertices.removeLast(2)
    }
    
    private func constructSegment(around point: LFloat3) -> [Vertex] { [
        Vertex(
            position: point.translated(dX: halfWidth, dY: halfHeight),
            uvTextureIndex: UVIndex.noPositionFlat.rawValue
        ),
        Vertex(
            position: point.translated(dX: halfWidth, dY: -halfHeight),
            uvTextureIndex: UVIndex.noPositionFlat.rawValue
        ),
    ] }
}

class MetalLinkLine: MetalLinkObject {
    var lineMesh: MetalLinkLineMesh

    init(_ link: MetalLink) {
        self.lineMesh = MetalLinkLineMesh(link)
        super.init(link, mesh: lineMesh)
    }
    
    // Render mesh as triangle strip
    override func drawPrimitives(_ sdp: inout SafeDrawPass) {
        sdp.renderCommandEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: mesh.vertexCount)
    }
    
    func appendSegment(about point: LFloat3) {
        lineMesh.addSegment(at: point)
        mesh.deallocateVertexBuffer()
    }
    
    func popSegment() {
        lineMesh.popSegment()
        mesh.deallocateVertexBuffer()
    }
}
