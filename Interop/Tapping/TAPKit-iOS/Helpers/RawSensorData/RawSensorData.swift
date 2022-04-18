//
//  RawSensorData.swift
//  TAPKit
//
//  Created by Shahar Biran on 04/02/2020.
//  Copyright © 2020 Shahar Biran. All rights reserved.
//

import Foundation

@objc public class Point3 : NSObject {
    public let x : Double
    public let y : Double
    public let z : Double
    
    public override init() {
        self.x = 0
        self.y = 0
        self.z = 0
        super.init()
    }
	
    public init?(arr:[UInt8], sensitivityFactor:Double) {
        guard arr.count == 6 else { return nil }
        let x_i : Int16 = Int16(arr[1]) << 8 | Int16(arr[0])
        let y_i : Int16 = Int16(arr[3]) << 8 | Int16(arr[2])
        let z_i : Int16 = Int16(arr[5]) << 8 | Int16(arr[4])
        self.x = Double(x_i) * sensitivityFactor
        self.y = Double(y_i) * sensitivityFactor
        self.z = Double(z_i) * sensitivityFactor
        super.init()
    }

    public func makeString() -> String {
        return "{ x: \(String(format: "%.2f", self.x)), y: \(String(format: "%.2f", self.y)), z: \(String(format: "%.2f", self.z)) } "
    }
    
    public func rawString(delimeter:String) -> String {
        return "\(self.x)\(delimeter)\(self.y)\(delimeter)\(self.z)\(delimeter)"
    }
}

@objc public enum RawSensorDataType : Int {
    case None = 0
    case IMU = 1
    case Device = 2
}

@objc public class RawSensorData : NSObject {

    @objc public static let iIMU_GYRO = 0
    @objc public static let iIMU_ACCELEROMETER = 1
    @objc public static let iDEV_THUMB = 0
    @objc public static let iDEV_INDEX = 1
    @objc public static let iDEV_MIDDLE = 2
    @objc public static let iDEV_RING = 3
    @objc public static let iDEV_PINKY = 4
    
    public let timestamp : UInt32
    public let type : RawSensorDataType
    public var points : [Point3]
    
    public override init() {
        self.points = [Point3]()
        self.timestamp = 0
        self.type = .None
        super.init()
        
    }
    
    public init?(type:RawSensorDataType, timestamp:UInt32, arr:[UInt8], sensitivity:TAPRawSensorSensitivity) {
        self.points = [Point3]()
        self.timestamp = timestamp
        self.type = type
        var pointSensitivity = type == .Device ? TAPRawSensorSensitivity.kDeviceAccelerometer : TAPRawSensorSensitivity.kIMUGyro
        var range = Range.init(uncheckedBounds: (lower:0,upper:6))
        while (range.lowerBound < arr.count) {
            guard arr.indices.contains(range.upperBound-1) else { return nil }
            if let sensitivityFactor = sensitivity.sensitivityFactor(for: pointSensitivity) {
                if let point = Point3(arr: Array(arr[range.lowerBound ..< range.upperBound]), sensitivityFactor: sensitivityFactor) {
                    self.points.append(point)
                } else {
                    return nil
                }
            } else {
                return nil
            }
            range = Range.init(uncheckedBounds: (lower:range.lowerBound + 6, upper:range.upperBound + 6))
            if type == .IMU {
                pointSensitivity = TAPRawSensorSensitivity.kIMUAccelerometer
            }
        }
        
        // Final double-check
        if self.type == .IMU {
            guard self.points.count == 2 else { return nil }
        } else if self.type == .Device {
            guard self.points.count == 5 else { return nil }
        } else {
            return nil
        }
        super.init()
    }
    
    public func makeString() -> String {
        var typeString = "None"
        if self.type == .IMU {
            typeString = "IMU"
        } else if self.type == .Device {
            typeString = "Device"
        }
        
        var pointsString = ""
        for i in 0..<self.points.count {
            let p = self.points[i]
            pointsString.append(p.makeString())
        }
        
        return "Timestamp = \(self.timestamp), Type = \(typeString), points =\(pointsString)"
    }
    
    @objc public func rawString(delimeter:String) -> String {
        var typeString = "IMU";
        if self.type == .None {
            return "";
        } else if (self.type == .Device) {
            typeString = "DEVICE";
        }
        var pointsString = ""
        for i in 0..<self.points.count {
            let p = self.points[i];
            pointsString.append(p.rawString(delimeter: delimeter))
        }
        return "\(self.timestamp)\(delimeter)\(typeString)\(delimeter)\(pointsString)"
    }
    
    @objc public func getPoint(for index:Int) -> Point3? {
        if self.points.indices.contains(index) {
            return self.points[index]
        } else {
            return nil
        }
    }
}
