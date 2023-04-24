//
//  File.swift
//  
//
//  Created by Yves Tsai on 2023/4/19.
//

import Foundation

import CoreSDK

public extension FL_Info_st {
    
    var tripTimeSec: Int {
        self.trip_time_sec.toInt
    }
    
    var tripAvgSpeed: Float {
        self.trip_avg_speed
    }
    
    var totalOdo: Float {
        self.total_odo
    }
    
    var batteryTemperature: Int {
        self.battery_temperature.toInt
    }

    var batteryRelativeStateOfCharge: Int {
        self.battery_rsoc.toInt
    }
    
    var batteryRelativeStateOfHealth: Int {
        self.battery_rsoh.toInt
    }
}

public extension FL_Info_st {
    
    var hmiWarningLength: Int {
        self.HMI_warning_leng.toInt
    }
    
    var hmiWarningCodes: [Int] {
        withUnsafeBytes(of: self.HMI_warning_list, { [UInt8]($0) })
                    .chunked(into: 4)
                    .mapBytes
                    .filter({ $0 != 0 })
    }
    
    var hmiErrorLength: Int {
        self.HMI_error_leng.toInt
    }
    
    var hmiErrorCodes: [Int] {
        withUnsafeBytes(of: self.HMI_error_list, { [UInt8]($0) })
            .chunked(into: 4)
            .mapBytes
            .filter({ $0 != 0 })
    }
    
    var controllerWarningLength: Int {
        self.controller_warning_leng.toInt
    }

    var controllerWarningCodes: [Int] {
        withUnsafeBytes(of: self.controller_warning_list, { [UInt8]($0) })
                    .chunked(into: 4)
                    .mapBytes
                    .filter({ $0 != 0 })
    }
    
    var controllerErrorLength: Int {
        self.controller_error_leng.toInt
    }
    
    var controllerErrorCodes: [Int] {
        withUnsafeBytes(of: self.controller_error_list, { [UInt8]($0) })
            .chunked(into: 4)
            .mapBytes
            .filter({ $0 != 0 })
    }
    
    var batteryWarningLength: Int {
        self.battery_warning_leng.toInt
    }
    
    var batteryWarningCodes: [Int] {
        withUnsafeBytes(of: self.battery_warning_list, { [UInt8]($0) })
                    .chunked(into: 4)
                    .mapBytes
                    .filter({ $0 != 0 })
    }
    
    var batteryErrorLength: Int {
        self.battery_error_leng.toInt
    }
    
    var batteryErrorCodes: [Int] {
        withUnsafeBytes(of: self.battery_error_list, { [UInt8]($0) })
            .chunked(into: 4)
            .mapBytes
            .filter({ $0 != 0 })
    }
    
    private var hasWarning: Bool {
        if self.hmiWarningLength > 0 {
            return true
        } else if self.controllerWarningLength > 0 {
            return true
        } else if self.batteryWarningLength > 0 {
            return true
        } else {
            return false
        }
    }
    
    private var hasError: Bool {
        if self.hmiErrorLength > 0 {
            return true
        } else if self.controllerErrorLength > 0 {
            return true
        } else if self.batteryErrorLength > 0 {
            return true
        } else {
            return false
        }
    }
    
    private var hasWrongStatus: Bool {
        self.hasWarning || self.hasError
    }
    
    var isAutoDiagnosePassesd: Bool {
        !self.hasError
    }
}
