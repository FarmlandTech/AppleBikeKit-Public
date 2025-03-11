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
        // 2025.2.28 在 FW 的文件當中，將 torque 與 cadence 定義在同一個 Category 當中，無法區別兩個部件，所以在此分開定義。
        case torqueSensor
        case cadenceSensor
        case throttle
        case light
        case speedSensor
        case derailleur
        case tpms
        case noCategory  // 2025.2.28 在 FW 的文件當中 Category 為空，但有定義錯誤碼。
        case unknown
    }
    
    public var tranfer2WarningCodeType: StatusCodeType {
        switch self {
        case 1:
            return .hmi
        case 21...22:
            return .battery
        case 41:
            return .controller
        case 61:
            return .motor
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
        case 21...40:
            return .battery
        case 41...55:
            return .controller
        case 61...66:
            return .motor
        case 81...82:
            return .torqueSensor
        case 83:
            return .cadenceSensor
        case 91...92:
            return .throttle
        case 101:
            return .light
        case 111:
            return .speedSensor
        case 131:
            return .derailleur
        case 151...158:
            return .tpms
        case 161...180:
            return .noCategory
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
