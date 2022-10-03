//
//  ForceLayout.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 10/2/22.
//

import Foundation

class LForceLayout {
    // Just being formal
    typealias Vertex = CodeGrid
    typealias EdgeLength = Float
    typealias Position = LFloat3
    typealias Threshold = LFloat3
    typealias Iterations = Int
    typealias Force = LFloat3
    typealias CoolingFactor = Float
    
    // or constant; edges will be between grids, so this can likely be computed JIT and cached based on directories and w/e else
    typealias PositionFunction = (Vertex) -> Position
    
    typealias RepulsiveFunction = (Vertex, Vertex) -> Force
    typealias AttractiveFunction = (Vertex, Vertex) -> Force
    
    let snapping: WorldGridSnapping = .init()
    
    func doLayout(
        allVertices: [Vertex],
        repulsiveFunction: RepulsiveFunction,
        attractiveFunction: AttractiveFunction,
        edgeLength: EdgeLength,
        maxIterations: Iterations,
        forceThreshold: Threshold,
        coolingFactor: CoolingFactor
    ) {
        var iterations: Iterations = 0
        var currentMaxForce: Force = .zero
        let maxThreshold = distance(.zero, forceThreshold)
        
        var shouldRepeat: Bool {
            maxIterations > 0
            && (iterations == 0
            || (
                iterations < maxIterations
                && distance(.zero, currentMaxForce) > maxThreshold)
            )
        }
        
        while shouldRepeat {
            var attractiveForces = [Vertex: [Vertex: Force]]()
            func getAttractive(_ a: Vertex, _ b: Vertex) -> Force {
                if let aToB = attractiveForces[a]?[b] { return aToB }
                let newForce = attractiveFunction(a, b)
                attractiveForces[a, default: [Vertex: Force]()][b] = newForce
                return newForce
            }
            
            var repulsiveForces = [Vertex: [Vertex: Force]]()
            func getRepulsive(_ a: Vertex, _ b: Vertex) -> Force {
                if let aToB = repulsiveForces[a]?[b] { return aToB }
                let newForce = repulsiveFunction(a, b)
                repulsiveForces[a, default: [Vertex: Force]()][b] = newForce
                return newForce
            }
            
            // Sum of forces between all vertices
            var finalForces = [Vertex: Force]()
            
            // Use array copy to pop last and reduce repeat iterations
            var remainingVertices = Array(allVertices)
            while let currentVertex = remainingVertices.popLast() {
                let sumRepulsive = remainingVertices.reduce(into: Force.zero) { finalForce, otherVertex in
                    if currentVertex.id == otherVertex.id { return }
                    finalForce += getRepulsive(currentVertex, otherVertex)
                }
                
                let sumAttractive = snapping.gridsRelativeTo(currentVertex).reduce(into: Force.zero) { finalForce, otherVertex in
                    if currentVertex.id == otherVertex.targetGrid.id { return }
                    finalForce += getAttractive(currentVertex, otherVertex.targetGrid)
                }
                
                // Compute and store final force, store current maximum
                let totalForceOnVertex = sumRepulsive + sumAttractive
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
