//
//  IntExtension.swift
//  
//
//  Created by Yves Tsai on 2023/4/19.
//

import Foundation

extension UInt32 {
    
    var toInt: Int {
        Int(self)
    }
}

extension Int8 {
    
    var toInt: Int {
        Int(self)
    }
}

extension Int {
    public enum StatusCodeType {
        case hmi
        case battery
        case controller
        case motor
        case torque
        case throttle
        case light
        case derailleur
        case tpms
        case unknown
    }
    
    public var tranfer2WarningCodeType: StatusCodeType {
        switch self {
        case 1:
            return .hmi
        case 2:
            return .controller
        case 101:
            return .light
        case 151...152:
            return .tpms
        default:
            return .unknown
        }
    }
    
    @available(*, deprecated, message: "經過會議，已重新定義診斷流程，所以完全不應該使用到此方法！")
    public var tranfer2DismaWarningCodeType: StatusCodeType {
        switch self {
        case 1, 151...152:
            return .hmi
        case 2, 101:
            return .controller
        default:
            return .unknown
        }
    }
    
    public var tranfer2ErrorCodeType: StatusCodeType {
        switch self {
        case 1:
            return .hmi
        case 21...37:
            return .battery
        case 41...52:
            return .controller
        case 61...66:
            return .motor
        case 81...83:
            return .torque
        case 91...92:
            return .throttle
        case 101...102:
            return .light
        case 131:
            return .derailleur
        case 151...158:
            return .tpms
        default:
            return .unknown
        }
    }
    
    @available(*, deprecated, message: "經過會議，已重新定義診斷流程，所以完全不應該使用到此方法！")
    public var tranfer2DismatchErrorCodeType: StatusCodeType {
        switch self {
        case 1, 22...23, 42...52, 61...66, 81...83, 91...92, 101...102, 131:
            return .controller
        case 24...37:
            return .battery
        case 21, 41, 151...158:
            return .hmi
        default:
            return .unknown
        }
    }
}
