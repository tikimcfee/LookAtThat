//
//  TAPRawSensorSensitivity.swift
//  TAPKit
//
//  Created by Shahar Biran on 05/02/2020.
//  Copyright © 2020 Shahar Biran. All rights reserved.
//

import Foundation

@objc public class TAPRawSensorSensitivity : NSObject {
    
    private static let sensitivityFactors : [String : [Double]] = [
        TAPRawSensorSensitivity.kDeviceAccelerometer : [31.25, 3.90625, 7.8125, 15.625, 31.25],
        TAPRawSensorSensitivity.kIMUAccelerometer : [0.122, 0.061, 0.122, 0.244, 0.488],
        TAPRawSensorSensitivity.kIMUGyro : [17.5, 4.375, 8.75, 17.5, 35, 70]
    ]
    
    
    
    @objc public var deviceAccelerometer : UInt8 {
        get {
            return params[TAPRawSensorSensitivity.kDeviceAccelerometer] ?? TAPRawSensorSensitivity.range[TAPRawSensorSensitivity.kDeviceAccelerometer]!.default
        } set {
            params[TAPRawSensorSensitivity.kDeviceAccelerometer] = normalizeSensitivityValue(newValue, type: TAPRawSensorSensitivity.kDeviceAccelerometer)
        }
    }
    
    @objc public var imuGyro : UInt8 {
        get {
            return params[TAPRawSensorSensitivity.kIMUGyro] ?? TAPRawSensorSensitivity.range[TAPRawSensorSensitivity.kIMUGyro]!.default
        } set {
            params[TAPRawSensorSensitivity.kIMUGyro] = normalizeSensitivityValue(newValue, type: TAPRawSensorSensitivity.kIMUGyro)
        }
    }
    
    
    @objc public var imuAccelerometer : UInt8 {
        get {
            return params[TAPRawSensorSensitivity.kIMUAccelerometer] ?? TAPRawSensorSensitivity.range[TAPRawSensorSensitivity.kIMUAccelerometer]!.default
        } set {
            params[TAPRawSensorSensitivity.kIMUAccelerometer] = normalizeSensitivityValue(newValue, type: TAPRawSensorSensitivity.kIMUAccelerometer)
        }
    }
    
    public static let kDeviceAccelerometer : String = "DeviceAccelerometer"
    public static let kIMUGyro : String = "IMUGyro"
    public static let kIMUAccelerometer : String = "IMUAccelerometer"
    
    private var params : [String:UInt8]!
    
    static let order : [String] = [TAPRawSensorSensitivity.kDeviceAccelerometer, TAPRawSensorSensitivity.kIMUGyro, TAPRawSensorSensitivity.kIMUAccelerometer]
    
    static let range : [String:(default:UInt8, low:UInt8, high:UInt8)] = [
        TAPRawSensorSensitivity.kDeviceAccelerometer: (default:UInt8(0), low:UInt8(0), high:UInt8(4)),
        TAPRawSensorSensitivity.kIMUAccelerometer: (default:UInt8(0), low:UInt8(0), high:UInt8(4)),
        TAPRawSensorSensitivity.kIMUGyro: (default:UInt8(0), low:UInt8(0), high:UInt8(5))
    ]

    @objc public override init() {
        self.params = [String:UInt8]()
        
        super.init()
        self.params[TAPRawSensorSensitivity.kDeviceAccelerometer] = TAPRawSensorSensitivity.range[TAPRawSensorSensitivity.kDeviceAccelerometer]!.default
        self.params[TAPRawSensorSensitivity.kIMUGyro] = TAPRawSensorSensitivity.range[TAPRawSensorSensitivity.kIMUGyro]!.default
        self.params[TAPRawSensorSensitivity.kIMUAccelerometer] = TAPRawSensorSensitivity.range[TAPRawSensorSensitivity.kIMUAccelerometer]!.default
    }
    
    @objc public init(deviceAccelerometer:Int, imuGyro:Int, imuAccelerometer:Int) {
        self.params = [String:UInt8]()
        
        super.init()
        self.params[TAPRawSensorSensitivity.kDeviceAccelerometer] = normalizeSensitivityValue(UInt8(deviceAccelerometer), type: TAPRawSensorSensitivity.kDeviceAccelerometer)
        self.params[TAPRawSensorSensitivity.kIMUGyro] = normalizeSensitivityValue(UInt8(imuGyro), type: TAPRawSensorSensitivity.kIMUGyro)
        self.params[TAPRawSensorSensitivity.kIMUAccelerometer] = normalizeSensitivityValue(UInt8(imuAccelerometer), type: TAPRawSensorSensitivity.kIMUAccelerometer)
    }
    
    public static func title(rawSensorSensitivity:TAPRawSensorSensitivity?) -> String {
        var string = ""
        
        if let sens = rawSensorSensitivity {
            for i in 0..<TAPRawSensorSensitivity.order.count {
                let key = TAPRawSensorSensitivity.order[i]
                if let value = sens.params[key] {
                    string.append("\(key):\(sens.normalizeSensitivityValue(value, type:key)) ")
                } else {
                    string.append("\(key):\(TAPRawSensorSensitivity.range[key]!.default) ")
                }
            }
        } else {
            return title(rawSensorSensitivity: TAPRawSensorSensitivity())
        }
        return string
    }
    
    private func normalizeSensitivityValue(_ value:UInt8, type:String) -> UInt8 {
        if let rng = TAPRawSensorSensitivity.range[type] {
            return value <= rng.high ? (value >= rng.low ? value : rng.default) : rng.default
        } else {
            return 0
        }
        
    }
    
    public func bytes() -> [UInt8] {
        var result = [UInt8]()
        for i in 0..<TAPRawSensorSensitivity.order.count {
            let key = TAPRawSensorSensitivity.order[i]
            if let value = self.params[key] {
                result.append(normalizeSensitivityValue(value, type:key))
            } else {
                result.append(TAPRawSensorSensitivity.range[key]!.default)
            }
        }
        return result
    }
    
    public func sensitivityFactor(for param:String ) -> Double? {
        if let factorArray = TAPRawSensorSensitivity.sensitivityFactors[param],
            let factorIndex = self.params[param] {
            if factorArray.indices.contains(Int(factorIndex)) {
                return factorArray[Int(factorIndex)]
            }
        }
        return nil
    }
    
}
