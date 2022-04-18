//
//  VersionNumber.swift
//  TAPKit
//
//  Created by Shahar Biran on 19/02/2020.
//  Copyright © 2020 Shahar Biran. All rights reserved.
//

import Foundation

class VersionNumber {
    
    private static let delimiter = "."
    private static let digits = 2
    private static let multHigh = Int(pow(Double(10), Double(VersionNumber.digits*2)))
    private static let multLow = Int(pow(Double(10), Double(VersionNumber.digits)))
    
    public static func data2Int(data:Data) -> Int? {
        if let str = String(data: data, encoding: String.Encoding.utf8) {
            return VersionNumber.string2Int(str: str)
        }
        return nil
    }
    
    public static func string2Int(str:String) -> Int? {
        var major = 0
        var minor = 0
        var build = 0
        let components = str.components(separatedBy: VersionNumber.delimiter)
    
        if components.count >= 2 {
            if let iMajor = Int(components[0]),
                let iMinor = Int(components[1]) {
                major = iMajor
                minor = iMinor
                if components.count >= 3 {
                    if let iBuild = Int(components[2]) {
                        build = iBuild
                    }
                }
                if (major < VersionNumber.multLow && minor < VersionNumber.multLow && build < VersionNumber.multLow) {
                    // All valid
                    return major*VersionNumber.multHigh + minor*VersionNumber.multLow + build
                }
            }
        }
        return nil
    }
    
    public static func int2String(_ version:Int) -> String? {
        let major = Int(version / VersionNumber.multHigh)
        let minor = Int(version % VersionNumber.multHigh / VersionNumber.multLow)
        let build = Int(version % VersionNumber.multLow)
        return "\(major)\(VersionNumber.delimiter)\(minor)\(VersionNumber.delimiter)\(build)"
    }
}


