//
//  DeviceInfoExtension.swift
//  
//
//  Created by Yves Tsai on 2023/4/19.
//

import Foundation

import CoreSDKSourceCode

public extension FL_Info_st {
    
    var hmiWarningCodes: [Int] {
        withUnsafeBytes(of: self.HMI_warning_list, { [UInt8]($0) })
                    .chunked(into: 4)
                    .mapBytes
                    .filter({ $0 != 0 })
    }
    
    var hmiErrorCodes: [Int] {
        withUnsafeBytes(of: self.HMI_error_list, { [UInt8]($0) })
            .chunked(into: 4)
            .mapBytes
            .filter({ $0 != 0 })
    }
    
    var controllerWarningCodes: [Int] {
        withUnsafeBytes(of: self.controller_warning_list, { [UInt8]($0) })
                    .chunked(into: 4)
                    .mapBytes
                    .filter({ $0 != 0 })
    }
    
    var controllerErrorCodes: [Int] {
        withUnsafeBytes(of: self.controller_error_list, { [UInt8]($0) })
            .chunked(into: 4)
            .mapBytes
            .filter({ $0 != 0 })
    }
    
    var batteryWarningCodes: [Int] {
        withUnsafeBytes(of: self.battery_warning_list, { [UInt8]($0) })
                    .chunked(into: 4)
                    .mapBytes
                    .filter({ $0 != 0 })
    }
    
    var batteryErrorCodes: [Int] {
        withUnsafeBytes(of: self.battery_error_list, { [UInt8]($0) })
            .chunked(into: 4)
            .mapBytes
            .filter({ $0 != 0 })
    }
    
    private var hasWarning: Bool {
        if self.HMI_warning_leng > 0 {
            return true
        } else if self.controller_warning_leng > 0 {
            return true
        } else if self.battery_warning_leng > 0 {
            return true
        } else {
            return false
        }
    }
    
    private var hasError: Bool {
        if self.HMI_error_leng > 0 {
            return true
        } else if self.controller_error_leng > 0 {
            return true
        } else if self.battery_error_leng > 0 {
            return true
        } else {
            return false
        }
    }
    
    var hasWrongStatus: Bool {
        self.hasWarning || self.hasError
    }
    
    var isAutoDiagnosePassesd: Bool {
        !self.hasError
    }
}

public extension FL_Info_st {
    var warningCodes: [Int] {
        self.hmiWarningCodes + self.batteryWarningCodes + self.controllerWarningCodes
    }
    
    var errorCodes: [Int] {
        self.hmiErrorCodes + self.batteryErrorCodes + self.controllerErrorCodes
    }
    
    var ableRideRange: Double {
        switch self.battery_rsoc {
        case 0..<10:
            return 2.2
        case 10..<20:
            return 4.4
        case 20..<30:
            return 6.6
        case 30..<40:
            return 8.8
        case 40..<50:
            return 11
        case 50..<60:
            return 13.2
        case 60..<70:
            return 15.4
        case 70..<80:
            return 17.6
        case 80..<90:
            return 19.8
        case 90...100:
            return 22
        default :
            return 0
        }
    }
}
