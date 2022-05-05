//
//  SCNAction+Extensions.swift
//  SCNBezier
//
//  Created by Max Cobb on 08/10/2018.
//  Copyright © 2018 Max Cobb. All rights reserved.
//

import SceneKit

public extension SCNAction {
	/// Move along a SCNBezierPath
	///
	/// - Parameters:
	///   - path: SCNBezierPath to animate along
	///   - duration: time to travel the entire path
	///   - fps: how frequent the position should be updated (default 30)
	///   - interpolator: time interpolator for easing
	/// - Returns: SCNAction to be applied to a node
	class func moveAlong(
		path: SCNBezierPath, duration: TimeInterval, fps: Int = 30,
		interpolator: ((TimeInterval) -> TimeInterval)? = nil
	) -> SCNAction {
		let actions = path.getNPoints(count: Int(duration) * fps, interpolator: interpolator).map { (point) -> SCNAction in
			let tInt = 1 / TimeInterval(fps)
			return SCNAction.move(to: point, duration: tInt)
		}
		return SCNAction.sequence(actions)
	}

	/// Move along a Bezier Path represented by a list of SCNVector3
	///
	/// - Parameters:
	///   - path: List of points to for m Bezier Path to animate along
	///   - duration: time to travel the entire path
	///   - fps: how frequent the position should be updated (default 30)
	///   - interpolator: time interpolator for easing (see InterpolatorFunctions)
	/// - Returns: SCNAction to be applied to a node
	class func moveAlong(
		bezier path: [SCNVector3], duration: TimeInterval,
		fps: Int = 30, interpolator: ((TimeInterval) -> TimeInterval)? = nil
	) -> SCNAction {
		return SCNAction.moveAlong(
			path: SCNBezierPath(points: path),
			duration: duration, fps: fps,
			interpolator: interpolator
		)
	}
}

//func makeLineNodeBetween(
//    positionA: SCNVector3,
//    positionB: SCNVector3,
//    inScene: SCNScene
//) -> (SCNNode, SCNCylinder) {
//    let vector = SCNVector3(
//        positionA.x - positionB.x,
//        positionA.y - positionB.y,
//        positionA.z - positionB.z
//    )
//    
//    let distance = sqrt(
//        vector.x * vector.x
//        + vector.y * vector.y
//        + vector.z * vector.z
//    )
//    
//    let midPosition = SCNVector3 (
//        x: (positionA.x + positionB.x) / 2,
//        y: (positionA.y + positionB.y) / 2,
//        z: (positionA.z + positionB.z) / 2
//    )
//    
//    let lineGeometry = SCNCylinder()
//    lineGeometry.radius = 0.05
//    lineGeometry.height = distance
//    lineGeometry.radialSegmentCount = 5
//    
//    let lineNode = SCNNode(geometry: lineGeometry)
//    lineNode.position = midPosition
//    lineNode.look(
//        at: positionB,
//        up: inScene.rootNode.worldUp,
//        localFront: lineNode.worldUp
//    )
//    
//    return (lineNode, lineGeometry)
//}
