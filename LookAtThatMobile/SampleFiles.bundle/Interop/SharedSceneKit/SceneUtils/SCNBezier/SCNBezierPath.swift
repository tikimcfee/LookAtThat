//
//  SCNBezierPath.swift
//  SCNBezier
//
//  Created by Max Cobb on 08/10/2018.
//  Copyright © 2018 Max Cobb. All rights reserved.
//

import SceneKit

public class SCNBezierPath {
	private let points: [SCNVector3]
	public init(points: [SCNVector3]) {
		self.points = points
	}
	/// Get position along bezier curve at a given time
	///
	/// - Parameter time: Time as a percentage along bezier curve
	/// - Returns: position on the bezier curve
	public func posAt(time: TimeInterval) -> SCNVector3 {
		guard let first = self.points.first, let last = self.points.last else {
			print("NO POINTS IN SCNBezierPath")
			return SCNVector3Zero
		}
		if time == 0 {
			return first
		} else if time == 1 {
			return last
		}

		#if os(macOS)
		let tFloat = CGFloat(time)
		#else
		let tFloat = Float(time)
		#endif

		var high = self.points.count
		var current = 0
		var rtn = self.points
		while high > 0 {
			while current < high - 1 {
				rtn[current] = rtn[current] * (1 - tFloat) + rtn[current + 1] * tFloat
				current += 1
			}
			high -= 1
			current = 0
		}
		return rtn.first!
	}
	/// Collection of points evenly separated along the bezier curve from beginning to end
	///
	/// - Parameters:
	///   - count: how many points you want
	///   - interpolator: time interpolator for easing
	/// - Returns: array of "count" points the points on the bezier curve
	public func getNPoints(
		count: Int, interpolator: ((TimeInterval) -> TimeInterval)? = nil
	) -> [SCNVector3] {
		var bezPoints: [SCNVector3] = Array(repeating: SCNVector3Zero, count: count)
		for time in 0..<count {
			let tNow = TimeInterval(time) / TimeInterval(count - 1)
			bezPoints[time] = self.posAt(
				time: interpolator == nil ? tNow : interpolator!(tNow)
			)
		}
		return bezPoints
	}
}
