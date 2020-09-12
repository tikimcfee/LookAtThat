//
//  InterpolatorFunctions.swift
//  SCNBezier
//
//  Created by Max Cobb on 11/10/2018.
//  Copyright © 2018 Max Cobb. All rights reserved.
//

import Foundation

public class InterpolatorFunctions {
	public static func bounceOut(tIn: TimeInterval) -> TimeInterval {
		var tFloat = min(max(tIn, 0), 1)
		if tFloat < (1/2.75) {
			return 7.5625*tFloat*tFloat
		} else if tFloat < (2/2.75) {
			tFloat -= 1.5/2.75
			return 7.5625*tFloat*tFloat + 0.75
		} else if tFloat < (2.5/2.75) {
			tFloat -= (2.25/2.75)
			return 7.5625*tFloat*tFloat + 0.9375
		} else {
			tFloat -= 2.625/2.75
			return 7.5625*tFloat*tFloat + 0.984375
		}
	}

	public static func easeInExpo(tIn: TimeInterval) -> TimeInterval {
		let tClamped = min(max(tIn, 0), 1)
		return tClamped == 0 ? 0 : pow(2, 10 * (tClamped - 1))
	}

	public static func easeOutExpo(tIn: TimeInterval) -> TimeInterval {
		let tClamped = min(max(tIn, 0), 1)
		return tClamped == 1 ? 1 : (1 - pow(2, -10 * tClamped))
	}

	public static func easeInOutExpo(tIn: TimeInterval) -> TimeInterval {
		var tClamped = min(max(tIn, 0), 1)
		if tClamped==0 || tClamped == 1 { return tClamped }
		tClamped *= 2
		if tClamped < 1 { return 1/2 * pow(2, 10 * (tClamped - 1)) }
		return 1/2 * (2 - pow(2, -10 * (tClamped - 1)))
	}

}
