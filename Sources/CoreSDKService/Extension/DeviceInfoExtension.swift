//
//  DeviceInfoExtension.swift
//  
//
//  Created by Yves Tsai on 2023/4/19.
//

import Foundation

import CoreSDKSourceCode

public extension Apple_Info_st {
    
    public struct Code {
        public enum Species {
            case warning, error
        }
        
        public let species: Apple_Info_st.Code.Species
        public let source: DeviceType_enum
        public let value: Int
    }
    
    var hmiWarningCodes: [Apple_Info_st.Code] {
        withUnsafeBytes(of: self.HMI_warning_list, { [UInt8]($0) })
                    .chunked(into: 4)
                    .mapBytes
                    .filter({ $0 != 0 })
                    .map({ .init(species: .warning, source: SDK_FL_HMI, value: $0) })
    }
    
    var hmiErrorCodes: [Apple_Info_st.Code] {
        withUnsafeBytes(of: self.HMI_error_list, { [UInt8]($0) })
            .chunked(into: 4)
            .mapBytes
            .filter({ $0 != 0 })
            .map({ .init(species: .error, source: SDK_FL_HMI, value: $0) })
    }
    
    var controllerWarningCodes: [Apple_Info_st.Code] {
        withUnsafeBytes(of: self.controller_warning_list, { [UInt8]($0) })
                    .chunked(into: 4)
                    .mapBytes
                    .filter({ $0 != 0 })
                    .map({ .init(species: .warning, source: SDK_FL_CONTROLLER, value: $0) })
    }
    
    var controllerErrorCodes: [Apple_Info_st.Code] {
        withUnsafeBytes(of: self.controller_error_list, { [UInt8]($0) })
            .chunked(into: 4)
            .mapBytes
            .filter({ $0 != 0 })
            .map({ .init(species: .error, source: SDK_FL_CONTROLLER, value: $0) })
    }
    
    var mainBatteryWarningCodes: [Apple_Info_st.Code] {
        withUnsafeBytes(of: self.m_batt_warning_list, { [UInt8]($0) })
                    .chunked(into: 4)
                    .mapBytes
                    .filter({ $0 != 0 })
                    .map({ .init(species: .warning, source: SDK_FL_MAIN_BATT, value: $0) })
    }
    
    var subBatteryWarningCodes: [Apple_Info_st.Code] {
        withUnsafeBytes(of: self.s_batt_warning_list, { [UInt8]($0) })
                    .chunked(into: 4)
                    .mapBytes
                    .filter({ $0 != 0 })
                    .map({ .init(species: .warning, source: SDK_FL_SUB_BATT1, value: $0) })
    }
    
    var mainBatteryErrorCodes: [Apple_Info_st.Code] {
        withUnsafeBytes(of: self.m_batt_error_list, { [UInt8]($0) })
            .chunked(into: 4)
            .mapBytes
            .filter({ $0 != 0 })
            .map({ .init(species: .error, source: SDK_FL_MAIN_BATT, value: $0) })
    }
    
    var subBatteryErrorCodes: [Apple_Info_st.Code] {
        withUnsafeBytes(of: self.s_batt_error_list, { [UInt8]($0) })
            .chunked(into: 4)
            .mapBytes
            .filter({ $0 != 0 })
            .map({ .init(species: .error, source: SDK_FL_SUB_BATT1, value: $0) })
    }
    
    private var hasWarning: Bool {
        self.HMI_warning_leng + self.controller_warning_leng + self.m_batt_warning_leng + self.s_batt_warning_leng > 0
    }
    
    private var hasError: Bool {
        self.HMI_error_leng + self.controller_error_leng + self.m_batt_error_leng + self.s_batt_error_leng > 0
    }
    
    var hasWrongStatus: Bool {
        self.hasWarning || self.hasError
    }
    
    var isAutoDiagnosePassesd: Bool {
        !self.hasError
    }
    
    var warningCodes: [Apple_Info_st.Code] {
        self.hmiWarningCodes + self.mainBatteryWarningCodes + self.subBatteryWarningCodes + self.controllerWarningCodes
    }
    
    var errorCodes: [Apple_Info_st.Code] {
        self.hmiErrorCodes + self.mainBatteryErrorCodes + self.subBatteryErrorCodes + self.controllerErrorCodes
    }
}

public extension Apple_Info_st {
    var ableRideRange: Double {
        let totalRsoc: Double = .init(self.m_batt_rsoc + self.s_batt_rsoc)
        if totalRsoc <= 200 {
            return 2.2 * Double(Int(totalRsoc / 10) + 1)
        } else {
            return 0
        }
    }
}

public protocol DeviceInfo {
    func asAppleDeviceInfo() throws -> Apple_Info_st
    func asOrangeDeviceInfo() throws -> Orange_Info_st
    func asCherryDeviceInfo() throws -> Cherry_Info_st
}


extension Apple_Info_st: DeviceInfo {
    public func asAppleDeviceInfo() throws -> Apple_Info_st {
        self
    }
    
    public func asOrangeDeviceInfo() throws -> Orange_Info_st {
        throw Tenant.Error.protocolMethodNotValid(#function)
    }
    
    public func asCherryDeviceInfo() throws -> Cherry_Info_st {
        throw Tenant.Error.protocolMethodNotValid(#function)
    }
}

extension Orange_Info_st: DeviceInfo {
    public func asAppleDeviceInfo() throws -> Apple_Info_st {
        throw Tenant.Error.protocolMethodNotValid(#function)
    }
    
    public func asCherryDeviceInfo() throws -> Cherry_Info_st {
        throw Tenant.Error.protocolMethodNotValid(#function)
    }
    
    public func asOrangeDeviceInfo() throws -> Orange_Info_st {
        self
    }
}

extension Cherry_Info_st: DeviceInfo {
    public func asAppleDeviceInfo() throws -> Apple_Info_st {
        throw Tenant.Error.protocolMethodNotValid(#function)
    }
    
    public func asOrangeDeviceInfo() throws -> Orange_Info_st {
        throw Tenant.Error.protocolMethodNotValid(#function)
    }
    
    public func asCherryDeviceInfo() throws -> Cherry_Info_st {
        self
    }
}
