//
//  ForceLayout.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 10/2/22.
//

import Foundation
import MetalLink
import MetalLinkHeaders
import MetalLinkResources
import Metal

struct LForceLayout2 {
    func calculateForces(
        nodes: inout [ForceLayoutNode],
        edges: inout [ForceLayoutEdge]
    ) {
        for (index, node) in nodes.enumerated() {
            // Reset forces
            var node = node
            node.force = .zero

            // Calculate repulsive forces
            for (otherIndex, otherNode) in nodes.enumerated() where otherIndex != index {
                let dx = node.fposition.x - otherNode.fposition.x
                let dy = node.fposition.y - otherNode.fposition.y
                let dz = node.fposition.z - otherNode.fposition.z
                let distance = sqrt(dx*dx + dy*dy + dz*dz)
                
                let force = (node.mass * otherNode.mass) / pow(distance, 2)
                let forceDirection = (dx: dx/distance, dy: dy/distance, dz: dz/distance)
                
                node.force.x -= force * forceDirection.dx
                node.force.y -= force * forceDirection.dy
                node.force.z -= force * forceDirection.dz
            }
            nodes[index] = node
        }

        // Calculate attractive forces
        for edge in edges {
            var node1 = nodes[Int(edge.node1)]
            var node2 = nodes[Int(edge.node2)]
            
            let dx = node1.fposition.x - node2.fposition.x
            let dy = node1.fposition.y - node2.fposition.y
            let dz = node1.fposition.z - node2.fposition.z
            let distance = sqrt(dx*dx + dy*dy + dz*dz)
            
            let force = edge.strength * distance
            let forceDirection = (dx: dx/distance, dy: dy/distance, dz: dz/distance)
            
            node1.force.x += force * forceDirection.dx
            node1.force.y += force * forceDirection.dy
            node1.force.z += force * forceDirection.dz
            
            node2.force.x -= force * forceDirection.dx
            node2.force.y -= force * forceDirection.dy
            node2.force.z -= force * forceDirection.dz
            
            nodes[Int(edge.node1)] = node1
            nodes[Int(edge.node2)] = node2
        }
    }
    
    func updateNodes(nodes: inout [ForceLayoutNode], deltaTime: Float) {
        for (index, node) in nodes.enumerated() {
            // Update velocity
            var node = node
            node.velocity.x += node.force.x / node.mass * deltaTime
            node.velocity.y += node.force.y / node.mass * deltaTime
            node.velocity.z += node.force.z / node.mass * deltaTime

            // Update position
            node.fposition.x += node.velocity.x * deltaTime
            node.fposition.y += node.velocity.y * deltaTime
            node.fposition.z += node.velocity.z * deltaTime
            nodes[index] = node
        }
    }
    
}
    
    
struct LForceLayout {
    // Just being formal
    typealias Vertex = CodeGrid
    typealias Position = LFloat3
    typealias Threshold = LFloat3
    typealias Iterations = Int
    typealias Force = LFloat3
    typealias CoolingFactor = Float
    
    // or constant; edges will be between grids, so this can likely be computed JIT and cached based on directories and w/e else
    typealias PositionFunction = (Vertex) -> Position
    
    typealias RepulsiveFunction = (Vertex, Vertex) -> Force
    typealias AttractiveFunction = (Vertex, Vertex) -> Force
    typealias IdealLengthFunction = (Vertex, Vertex) -> Float
    
    let snapping: WorldGridSnapping
    
    func doLayout(
        allVertices: [Vertex],
        repulsiveFunction: RepulsiveFunction,
        attractiveFunction: AttractiveFunction,
        maxIterations: Iterations,
        forceThreshold: Threshold,
        coolingFactor: CoolingFactor
    ) {
        var iterations: Iterations = 0
        var currentMaxForce: Force = .zero
//        let maxThreshold = forceThreshold.magnitude
        
        var shouldRepeat: Bool {
            guard iterations > 0 else { return true }
            let underMaxIterations = iterations < maxIterations
            let overForceThreshold = currentMaxForce.magnitude > forceThreshold.magnitude
            return underMaxIterations && overForceThreshold
        }
        
//        var shouldRepeat: Bool {
//            maxIterations > 0
//            && (iterations == 0
//            || (
//                iterations < maxIterations
//                && distance(.zero, currentMaxForce) > maxThreshold)
//            )
//        }
        
        while shouldRepeat {
            Thread.sleep(forTimeInterval: 0.01)
//            var attractiveForces = [Vertex: [Vertex: Force]]()
            func getAttractive(_ a: Vertex, _ b: Vertex) -> Force {
//                if let aToB = attractiveForces[a]?[b] { return aToB }
                let newForce = attractiveFunction(a, b)
//                attractiveForces[a, default: [Vertex: Force]()][b] = newForce
                return newForce
            }
            
//            var repulsiveForces = [Vertex: [Vertex: Force]]()
            func getRepulsive(_ a: Vertex, _ b: Vertex) -> Force {
//                if let aToB = repulsiveForces[a]?[b] { return aToB }
                let newForce = repulsiveFunction(a, b)
//                repulsiveForces[a, default: [Vertex: Force]()][b] = newForce
                return newForce
            }
            
            // Sum of forces between all vertices
            var finalForces = [Vertex: Force]()
            
            // Use array copy to pop last and reduce repeat iterations
            var remainingVertices = Array(allVertices)
            while let currentVertex = remainingVertices.popLast() {
                let sumRepulsive = remainingVertices.reduce(into: Force.zero) { finalForce, otherVertex in
                    if currentVertex.id == otherVertex.id { return }
                    let repulsive = getRepulsive(currentVertex, otherVertex)
//                    print("\(currentVertex.fileName) XXXX--> \(otherVertex.fileName)")
                    finalForce += repulsive
                }
                
                let sumAttractive = snapping.gridsRelativeTo(currentVertex).reduce(into: Force.zero) { finalForce, otherVertex in
                    if currentVertex.id == otherVertex.targetGrid.id { return }
                    let attractive = getAttractive(currentVertex, otherVertex.targetGrid)
//                    print("\(currentVertex.fileName) <--++++ \(otherVertex.targetGrid.fileName)")
                    finalForce += attractive
                }
                
                // Compute and store final force, store current maximum
                let totalForceOnVertex = sumRepulsive + sumAttractive
//                print("[f-total] <--", totalForceOnVertex)
                finalForces[currentVertex] = totalForceOnVertex
            }
            
            // Apply all forces
            var nextMaxForce: LFloat3 = .zero
            for currentVertex in allVertices {
                guard let computedForce = finalForces[currentVertex] else {
                    print("Missing force on \(currentVertex.id): \(currentVertex.fileName)")
                    return
                }
                nextMaxForce = max(nextMaxForce, computedForce)
                currentVertex.position = currentVertex.position + (coolingFactor * computedForce)
            }
            
            currentMaxForce = nextMaxForce
            iterations += 1
        }
    }
}
