//
//  TAPMode.swift
//  TAPKit
//
//  Created by Shahar Biran on 26/03/2018.
//  Copyright © 2018 Shahar Biran. All rights reserved.
//

import Foundation


@objc public class TAPInputMode : NSObject {

    @objc public static let kController : String = "Controller"
    @objc public static let kText : String = "Text"
    @objc public static let kRawSensor : String = "RawSensor"
    @objc public static let kControllerWithMouseHID : String = "ControllerWithMouseHID"
    
    private static let modeByte : [String:UInt8] = [TAPInputMode.kController : 0x1, TAPInputMode.kText : 0x0, TAPInputMode.kRawSensor : 0xa, TAPInputMode.kControllerWithMouseHID : 0x3]
    
    public var sensitivity : TAPRawSensorSensitivity?
    public let type:String
    
    private init(type:String, sensitivity:TAPRawSensorSensitivity? = nil) {
        self.type = type
        self.sensitivity = sensitivity
        super.init()
    }
    
    static func modeWhenDisabled() -> TAPInputMode {
        return TAPInputMode(type: kText)
    }
    
    static func defaultMode() -> TAPInputMode {
        return TAPInputMode(type: kController)
    }
    
    @objc public static func controller() -> TAPInputMode {
        return TAPInputMode(type: TAPInputMode.kController)
    }
    
    @objc public static func text() -> TAPInputMode {
        return TAPInputMode(type: TAPInputMode.kText)
    }
    
    @objc public static func rawSensor(sensitivity:TAPRawSensorSensitivity) -> TAPInputMode {
        return TAPInputMode(type: TAPInputMode.kRawSensor, sensitivity: sensitivity)
    }

    @objc public static func controllerWithMouseHID() -> TAPInputMode {
        return TAPInputMode(type: TAPInputMode.kControllerWithMouseHID)
    }
    
    func data() -> Data? {
        guard let modeValue = TAPInputMode.modeByte[self.type] else {
            return nil
        }
        
        var sensitivityArray = [UInt8]()
        
        if self.type == TAPInputMode.kRawSensor {
            if let sens = self.sensitivity {
                sensitivityArray = sens.bytes()
            } else {
                return nil
            }
        }
        let bytes : [UInt8] = [0x3,0xc,0x0,modeValue] + sensitivityArray
        let d = Data(bytes)
        return d
    }
    
    func title() -> String {
        if self.type != TAPInputMode.kRawSensor {
            return self.type
        } else {
            return "Raw Sensor Mode (with) Sensitivities: \(TAPRawSensorSensitivity.title(rawSensorSensitivity: self.sensitivity))"
        }
    }
}
