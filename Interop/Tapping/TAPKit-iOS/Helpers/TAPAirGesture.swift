//
//  TAPAirGesture.swift
//  TAPKit
//
//  Created by Shahar Biran on 05/02/2020.
//  Copyright © 2020 Shahar Biran. All rights reserved.
//

import Foundation

@objc public enum TAPAirGesture : Int {
    case OneFingerUp = 2
    case TwoFingersUp = 3
    case OneFingerDown = 4
    case TwoFingersDown = 5
    case OneFingerLeft = 6
    case TwoFingersLeft = 7
    case OnefingerRight = 8
    case TwoFingersRight = 9
    case IndexToThumbTouch = 10
    case MiddleToThumbTouch = 11
}

class TAPAirGestureHelper {
    private init() {
        
    }
    
    static func tapToAirGesture(_ combination:UInt8) -> TAPAirGesture? {
        if combination == 2 {
            return .IndexToThumbTouch
        } else if combination == 4 {
            return .MiddleToThumbTouch
        }
        return nil
    }
}
