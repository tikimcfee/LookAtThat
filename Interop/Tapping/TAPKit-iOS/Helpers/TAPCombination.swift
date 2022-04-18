//
//  TAPCombination.swift
//  TAPKit
//
//  Created by Shahar Biran on 27/03/2018.
//  Copyright © 2018 Shahar Biran. All rights reserved.
//

import Foundation

public enum Fingers: Int, CustomStringConvertible, CaseIterable {
	case thumb = 0
	case index
	case middle
	case ring
	case pinky
	
	public static var set: Set<Fingers> = Set(Fingers.allCases)
	
	public static func fromIntCombination(_ combination: UInt8) -> [Fingers] {
		TAPCombination
			.computeTapStatesFromBinarySequence(combination)
			.enumerated()
			.reduce(into: []) { result, offsetAndTapState in
				guard let parsed = Fingers(rawValue: offsetAndTapState.offset),
					  offsetAndTapState.element
				else { return }
				result.append(parsed)
			}
	}
	
//	private static func from(offset: Int) -> Fingers? {
//		switch offset { 
//			case 0: return .thumb
//			case 1: return .index
//			case 2: return .middle
//			case 3: return .ring
//			case 4: return .pinky
//			default: return nil
//		}
//	}
	
	public var description: String {
		switch self {
			case .thumb: return "Thumb"
			case .index: return "Index"
			case .middle: return "Middle"
			case .ring: return "Ring"
			case .pinky: return "Pinky"
		}
	}
}

@objc public class TAPCombination : NSObject {
    override private init() {
        super.init()
    }
    
    @objc public static let allFingers = 31
    
    @objc public static func fromFingers(_ thumb:Bool, _ index:Bool, _ middle:Bool, _ ring:Bool, _ pinky:Bool) -> UInt8 {
        let fingers = [thumb, index, middle, ring, pinky]
        var res : UInt8 = 0
        for i in 0..<fingers.count {
            if fingers[i] {
                res = res | ( 0b00001 << i)
            }
        }
        return res
    }

    @objc public static func computeTapStatesFromBinarySequence(_ combination:UInt8) -> [Bool] {
        return [combination & 0b00001 > 0, 
				combination & 0b00010 > 0, 
				combination & 0b00100 > 0, 
				combination & 0b01000 > 0, 
				combination & 0b10000 > 0]
    }
}
