//
//  CommunicationPartType.swift
//  
//
//  Created by Yves Tsai on 2023/4/20.
//

import Foundation

import CoreSDKSourceCode

public enum CommunicationPartType: Int {
    
    case HMI = 1
    case Controller = 2
    case MainBatt = 3
    case SubBatt1 = 4
    case SubBatt2 = 5
    case Display = 6
    case IOT = 7
    case EDerailleur = 8
    case ELock = 9
    case Dongle = 10
    case Unknown = 255
    
    /// 由 swift 的 communication part type enum 去回推 CoreSDK 的 DeviceType_enum 。
    public var coreType: DeviceType_enum {
        switch self {
        case .HMI:
            return SDK_FL_HMI
        case .Controller:
            return SDK_FL_CONTROLLER
        case .MainBatt:
            return SDK_FL_MAIN_BATT
        case .SubBatt1:
            return SDK_FL_SUB_BATT1
        case .SubBatt2:
            return SDK_FL_SUB_BATT2
        case .Display:
            return SDK_FL_DISPLAY
        case .IOT:
            return SDK_FL_IOT
        case .EDerailleur:
            return SDK_FL_E_DERAILLEUR
        case .ELock:
            return SDK_FL_E_LOCK
        case .Dongle:
            return SDK_FL_DONGLE
        case .Unknown:
            return SDK_UNKNOWN
        }
    }
}
