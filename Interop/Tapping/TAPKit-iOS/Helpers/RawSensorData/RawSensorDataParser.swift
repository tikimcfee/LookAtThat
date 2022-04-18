//
//  RawSensorDataParserQueue.swift
//  TAPKit
//
//  Created by Shahar Biran on 04/02/2020.
//  Copyright © 2020 Shahar Biran. All rights reserved.
//

import Foundation

class RawSensorDataParser {
    
    private static var dq = DispatchQueue(label: "RawSensorDataParserQueue")

    public static func parseWhole(data:Data, sensitivity:TAPRawSensorSensitivity, onMessageReceived:(@escaping (RawSensorData)->Void)) -> Void {
        let array = [UInt8](data)
        let metaLength = 4
        var metaOffset = 0
        var timestamp : UInt32 = 1
        var current = 1
        while (metaOffset + metaLength < array.count && timestamp > 0) {
            var meta : UInt32 = 0
            var add = 0
            
            memcpy(&meta, Array(array[metaOffset..<metaOffset + metaLength]), metaLength)
            if meta > 0 {
                let packet_type = (meta & UInt32(0x80000000)) >> 31;
                timestamp = UInt32(meta & UInt32(0x7fffffff));
                var type : RawSensorDataType = .None
                var messageRange = Range(uncheckedBounds: (lower:0, upper:0))
                
                if packet_type == 0 {
                    messageRange = Range(uncheckedBounds: (lower:metaOffset + metaLength, upper:metaOffset + metaLength + 12))
                    type = .IMU
                    add = 12
                } else if packet_type == 1 {
                    messageRange = Range(uncheckedBounds: (lower:metaOffset + metaLength, upper:metaOffset + metaLength + 30))
                    add = 30
                     type = .Device
                } else {
                    return
                }
                if type != .None {
                    if array.indices.contains(messageRange.upperBound) {
                        RawSensorDataParser.dq.sync {
                            RawSensorDataParser.parseSingle(type: type, timestamp: timestamp, arr: Array(array[messageRange.lowerBound..<messageRange.upperBound]), sensitivitiy: sensitivity, onMessageReceived: onMessageReceived)
                        }
                    }
                    
                }
                if timestamp == 0 {
                    return
                }
                if add == 0 {
                    return
                }
            } else {
                return
            }
            metaOffset = metaOffset + metaLength + add
            current = current + 1
        }
        
    }
    
    private static func parseSingle(type:RawSensorDataType, timestamp:UInt32, arr:[UInt8], sensitivitiy: TAPRawSensorSensitivity, onMessageReceived:((RawSensorData) -> Void)) -> Void {
        if let data = RawSensorData(type: type, timestamp: timestamp, arr: arr, sensitivity: sensitivitiy) {
            onMessageReceived(data)
        }
    }
    
}
