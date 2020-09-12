//
//  SCNVector3+Extensions.swift
//  SCNBezier
//
//  Created by Max Cobb on 08/10/2018.
//  Copyright © 2018 Max Cobb. All rights reserved.
//

import SceneKit

#if os(macOS)
public typealias VectorVal = CGFloat
#else
public typealias VectorVal = Float
#endif

internal func - (left: SCNVector3, right: SCNVector3) -> SCNVector3 {
	return SCNVector3Make(left.x - right.x, left.y - right.y, left.z - right.z)
}
internal func + (left: SCNVector3, right: SCNVector3) -> SCNVector3 {
	return SCNVector3Make(left.x + right.x, left.y + right.y, left.z + right.z)
}
internal func * (left: SCNVector3, right: VectorVal) -> SCNVector3 {
	return SCNVector3Make(left.x * right, left.y * right, left.z * right)
}
