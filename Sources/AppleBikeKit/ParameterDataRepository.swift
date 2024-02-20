//
//  ParameterDataRepository.swift
//  
//
//  Created by Yves Tsai on 2023/4/20.
//

import Foundation

import CoreSDKSourceCode
import CoreSDKService

/// 部件參數模型的倉庫，包括定義與緩存，以及小部分的邏輯。
public class ParameterDataRepository {
    
    /// 自定義的錯誤枚舉。
    public enum Error: Swift.Error {
        /// 透過名稱枚舉查詢部件參數時，搜尋失敗。
        case parameterDataNotFoundByName(ParameterData.Name)
        /// 透過相關資訊查詢部件參數時，搜尋失敗。
        case parameterDataNotFoundByArguments(DeviceType_enum, UInt8, UInt16, UInt16)
        /// 來自系統定義的例外，非自定義的錯誤。
        case exception(Swift.Error)
    }
    
    public let hmiBank0Parameters: [ParameterData] = [
        .init(name: .HmiSMID, partType: .HMI, bank: 0, address: 0, length: 15, type: String.self),
        .init(name: .HmiDMID, partType: .HMI, bank: 0, address: 15, length: 17, type: String.self),
        .init(name: .HmiSSN, partType: .HMI, bank: 0, address: 32, length: 32, type: String.self),
        .init(name: .HmiDSN, partType: .HMI, bank: 0, address: 64, length: 32, type: String.self),
        .init(name: .HmiFrame, partType: .HMI, bank: 0, address: 96, length: 32, type: String.self),
        .init(name: .HmiSaleDate, partType: .HMI, bank: 0, address: 128, length: 6, type: String.self),
        .init(name: .HmiFWAppVer, partType: .HMI, bank: 0, address: 134, length: 6, type: String.self),
        .init(name: .HmiFWBtlVer, partType: .HMI, bank: 0, address: 140, length: 6, type: String.self),
        .init(name: .HmiFWSdkVer, partType: .HMI, bank: 0, address: 146, length: 6, type: String.self),
        .init(name: .HmiHWVer, partType: .HMI, bank: 0, address: 152, length: 11, type: String.self),
        .init(name: .HmiParaVer, partType: .HMI, bank: 0, address: 163, length: 6, type: String.self),
        .init(name: .HmiProtocolVer, partType: .HMI, bank: 0, address: 169, length: 11, type: String.self),
        .init(name: .HmiBtDevName, partType: .HMI, bank: 0, address: 180, length: 22, type: String.self),
    ]
    
    public let hmiBank2Parameters: [ParameterData] = [
        .init(name: .DISP_UNIT_SW, partType: .HMI, bank: 2, address: 153, length: 1, type: Int.self)
    ]
    
    public let controllerBank0Parameters: [ParameterData] = [
        .init(name: .ControllerSMID, partType: .Controller, bank: 0, address: 0, length: 15, type: String.self),
        .init(name: .ControllerDMID, partType: .Controller, bank: 0, address: 15, length: 17, type: String.self),
        .init(name: .ControllerSSN, partType: .Controller, bank: 0, address: 32, length: 32, type: String.self),
        .init(name: .ControllerDSN, partType: .Controller, bank: 0, address: 64, length: 32, type: String.self),
        .init(name: .ControllerFrame, partType: .Controller, bank: 0, address: 96, length: 32, type: String.self),
        .init(name: .ControllerSaleDate, partType: .Controller, bank: 0, address: 128, length: 6, type: String.self),
        .init(name: .ControllerFWAppVer, partType: .Controller, bank: 0, address: 134, length: 6, type: String.self),
        .init(name: .ControllerFWBtlVer, partType: .Controller, bank: 0, address: 140, length: 6, type: String.self),
        .init(name: .ControllerFWSdkVer, partType: .Controller, bank: 0, address: 146, length: 6, type: String.self),
        .init(name: .ControllerHWVer, partType: .Controller, bank: 0, address: 152, length: 11, type: String.self),
        .init(name: .ControllerParaVer, partType: .Controller, bank: 0, address: 163, length: 6, type: String.self),
        .init(name: .ControllerProtocolVer, partType: .Controller, bank: 0, address: 169, length: 11, type: String.self),
        .init(name: .ControllerBtDevName, partType: .Controller, bank: 0, address: 180, length: 22, type: String.self),
    ]
    
    public let controllerBank1Parameters: [ParameterData] = [
        .init(name: .DISGUISE_BATT, partType: .Controller, bank: 1, address: 0, length: 1, type: Int.self),
        .init(name: .INFO_ODO, partType: .Controller, bank: 1, address: 217, length: 4, type: Int.self),
    ]
    
    public let controllerBank2Parameters: [ParameterData] = [
        .init(name: .SYS_PART_EN, partType: .Controller, bank: 2, address: 358, length: 4, type: [UInt8].self)
    ]
    
    public let controllerBank3Parameters: [ParameterData] = [
        .init(name: .BACKUP_ODO, partType: .Controller, bank: 2, address: 128, length: 4, type: Int.self),
        .init(name: .BACKUP_LAST_TIME_ODO, partType: .Controller, bank: 2, address: 148, length: 4, type: Int.self)
    ]
    
    public let batteryBank0Parameters: [ParameterData] = [
        .init(name: .BattSMID, partType: .MainBatt, bank: 0, address: 0, length: 15, type: String.self),
        .init(name: .BattDMID, partType: .MainBatt, bank: 0, address: 15, length: 17, type: String.self),
        .init(name: .BattSSN, partType: .MainBatt, bank: 0, address: 32, length: 32, type: String.self),
        .init(name: .BattDSN, partType: .MainBatt, bank: 0, address: 64, length: 32, type: String.self),
        .init(name: .BattFrame, partType: .MainBatt, bank: 0, address: 96, length: 32, type: String.self),
        .init(name: .BattSaleDate, partType: .MainBatt, bank: 0, address: 128, length: 6, type: String.self),
        .init(name: .BattFWAppVer, partType: .MainBatt, bank: 0, address: 134, length: 6, type: String.self),
        .init(name: .BattFWBtlVer, partType: .MainBatt, bank: 0, address: 140, length: 6, type: String.self),
        .init(name: .BattFWSdkVer, partType: .MainBatt, bank: 0, address: 146, length: 6, type: String.self),
        .init(name: .BattHWVer, partType: .MainBatt, bank: 0, address: 152, length: 11, type: String.self),
        .init(name: .BattParaVer, partType: .MainBatt, bank: 0, address: 163, length: 6, type: String.self),
        .init(name: .BattProtocolVer, partType: .MainBatt, bank: 0, address: 169, length: 11, type: String.self),
        .init(name: .BattBtDevName, partType: .MainBatt, bank: 0, address: 180, length: 22, type: String.self),
    ]
    
    /// 基礎部件的關鍵參數陣列。(應再根據類別再次拆分)
    public private(set) lazy var normalParameters: [ParameterData] = {
        self.hmiBank0Parameters +
        self.hmiBank2Parameters +
        self.controllerBank0Parameters +
        self.controllerBank1Parameters +
        self.controllerBank2Parameters +
        self.controllerBank3Parameters +
        self.batteryBank0Parameters
    }()
    
    /// 助力方案相關的參數陣列。
    public let assistLevelParameters:[ParameterData] = [
        .init(name: .LV1_MAX_AST_RATIO, partType: .Controller, bank: 2, address: 133, length: 2, type: Int.self),
        .init(name: .LV1_MIN_AST_RATIO, partType: .Controller, bank: 2, address: 135, length: 2, type: Int.self),
        .init(name: .LV1_AST_RATIO_STR_SPD, partType: .Controller, bank: 2, address: 137, length: 2, type: Int.self),
        .init(name: .LV1_AST_RATIO_END_SPD, partType: .Controller, bank: 2, address: 139, length: 2, type: Int.self),
        .init(name: .LV2_MAX_AST_RATIO, partType: .Controller, bank: 2, address: 141, length: 2, type: Int.self),
        .init(name: .LV2_MIN_AST_RATIO, partType: .Controller, bank: 2, address: 143, length: 2, type: Int.self),
        .init(name: .LV2_AST_RATIO_STR_SPD, partType: .Controller, bank: 2, address: 145, length: 2, type: Int.self),
        .init(name: .LV2_AST_RATIO_END_SPD, partType: .Controller, bank: 2, address: 147, length: 2, type: Int.self),
        .init(name: .LV3_MAX_AST_RATIO, partType: .Controller, bank: 2, address: 149, length: 2, type: Int.self),
        .init(name: .LV3_MIN_AST_RATIO, partType: .Controller, bank: 2, address: 151, length: 2, type: Int.self),
        .init(name: .LV3_AST_RATIO_STR_SPD, partType: .Controller, bank: 2, address: 153, length: 2, type: Int.self),
        .init(name: .LV3_AST_RATIO_END_SPD, partType: .Controller, bank: 2, address: 155, length: 2, type: Int.self),
    ]
    
    /// 里程相關的參數陣列。
    public let mileageRecordParameters: [ParameterData] = [
        .init(name: .UNIX_TIME_DAY1, partType: .MainBatt, bank: 2, address: 0, length: 4, type: Int.self),
        .init(name: .RECORD_ODO_DAY1, partType: .MainBatt, bank: 2, address: 4, length: 4, type: Int.self),
        .init(name: .UNIX_TIME_DAY2, partType: .MainBatt, bank: 2, address: 8, length: 4, type: Int.self),
        .init(name: .RECORD_ODO_DAY2, partType: .MainBatt, bank: 2, address: 12, length: 4, type: Int.self),
        .init(name: .UNIX_TIME_DAY3, partType: .MainBatt, bank: 2, address: 16, length: 4, type: Int.self),
        .init(name: .RECORD_ODO_DAY3, partType: .MainBatt, bank: 2, address: 20, length: 4, type: Int.self),
        .init(name: .UNIX_TIME_DAY4, partType: .MainBatt, bank: 2, address: 24, length: 4, type: Int.self),
        .init(name: .RECORD_ODO_DAY4, partType: .MainBatt, bank: 2, address: 28, length: 4, type: Int.self),
        .init(name: .UNIX_TIME_DAY5, partType: .MainBatt, bank: 2, address: 32, length: 4, type: Int.self),
        .init(name: .RECORD_ODO_DAY5, partType: .MainBatt, bank: 2, address: 36, length: 4, type: Int.self),
        .init(name: .UNIX_TIME_DAY6, partType: .MainBatt, bank: 2, address: 40, length: 4, type: Int.self),
        .init(name: .RECORD_ODO_DAY6, partType: .MainBatt, bank: 2, address: 44, length: 4, type: Int.self),
        .init(name: .UNIX_TIME_DAY7, partType: .MainBatt, bank: 2, address: 48, length: 4, type: Int.self),
        .init(name: .RECORD_ODO_DAY7, partType: .MainBatt, bank: 2, address: 52, length: 4, type: Int.self),
        .init(name: .UNIX_TIME_DAY8, partType: .MainBatt, bank: 2, address: 56, length: 4, type: Int.self),
        .init(name: .RECORD_ODO_DAY8, partType: .MainBatt, bank: 2, address: 60, length: 4, type: Int.self),
        .init(name: .UNIX_TIME_DAY9, partType: .MainBatt, bank: 2, address: 64, length: 4, type: Int.self),
        .init(name: .RECORD_ODO_DAY9, partType: .MainBatt, bank: 2, address: 68, length: 4, type: Int.self),
        .init(name: .UNIX_TIME_DAY10, partType: .MainBatt, bank: 2, address: 72, length: 4, type: Int.self),
        .init(name: .RECORD_ODO_DAY10, partType: .MainBatt, bank: 2, address: 76, length: 4, type: Int.self),
        .init(name: .UNIX_TIME_DAY11, partType: .MainBatt, bank: 2, address: 80, length: 4, type: Int.self),
        .init(name: .RECORD_ODO_DAY11, partType: .MainBatt, bank: 2, address: 84, length: 4, type: Int.self),
        .init(name: .UNIX_TIME_DAY12, partType: .MainBatt, bank: 2, address: 88, length: 4, type: Int.self),
        .init(name: .RECORD_ODO_DAY12, partType: .MainBatt, bank: 2, address: 92, length: 4, type: Int.self),
        .init(name: .UNIX_TIME_DAY13, partType: .MainBatt, bank: 2, address: 96, length: 4, type: Int.self),
        .init(name: .RECORD_ODO_DAY13, partType: .MainBatt, bank: 2, address: 100, length: 4, type: Int.self),
        .init(name: .UNIX_TIME_DAY14, partType: .MainBatt, bank: 2, address: 104, length: 4, type: Int.self),
        .init(name: .RECORD_ODO_DAY14, partType: .MainBatt, bank: 2, address: 108, length: 4, type: Int.self),
        .init(name: .UNIX_TIME_DAY15, partType: .MainBatt, bank: 2, address: 112, length: 4, type: Int.self),
        .init(name: .RECORD_ODO_DAY15, partType: .MainBatt, bank: 2, address: 116, length: 4, type: Int.self),
        .init(name: .UNIX_TIME_DAY16, partType: .MainBatt, bank: 2, address: 120, length: 4, type: Int.self),
        .init(name: .RECORD_ODO_DAY16, partType: .MainBatt, bank: 2, address: 124, length: 4, type: Int.self),
        .init(name: .UNIX_TIME_DAY17, partType: .MainBatt, bank: 2, address: 128, length: 4, type: Int.self),
        .init(name: .RECORD_ODO_DAY17, partType: .MainBatt, bank: 2, address: 132, length: 4, type: Int.self),
        .init(name: .UNIX_TIME_DAY18, partType: .MainBatt, bank: 2, address: 136, length: 4, type: Int.self),
        .init(name: .RECORD_ODO_DAY18, partType: .MainBatt, bank: 2, address: 140, length: 4, type: Int.self),
        .init(name: .UNIX_TIME_DAY19, partType: .MainBatt, bank: 2, address: 144, length: 4, type: Int.self),
        .init(name: .RECORD_ODO_DAY19, partType: .MainBatt, bank: 2, address: 148, length: 4, type: Int.self),
        .init(name: .UNIX_TIME_DAY20, partType: .MainBatt, bank: 2, address: 152, length: 4, type: Int.self),
        .init(name: .RECORD_ODO_DAY20, partType: .MainBatt, bank: 2, address: 156, length: 4, type: Int.self),
        .init(name: .UNIX_TIME_DAY21, partType: .MainBatt, bank: 2, address: 160, length: 4, type: Int.self),
        .init(name: .RECORD_ODO_DAY21, partType: .MainBatt, bank: 2, address: 164, length: 4, type: Int.self),
        .init(name: .UNIX_TIME_DAY22, partType: .MainBatt, bank: 2, address: 168, length: 4, type: Int.self),
        .init(name: .RECORD_ODO_DAY22, partType: .MainBatt, bank: 2, address: 172, length: 4, type: Int.self),
        .init(name: .UNIX_TIME_DAY23, partType: .MainBatt, bank: 2, address: 176, length: 4, type: Int.self),
        .init(name: .RECORD_ODO_DAY23, partType: .MainBatt, bank: 2, address: 180, length: 4, type: Int.self),
        .init(name: .UNIX_TIME_DAY24, partType: .MainBatt, bank: 2, address: 184, length: 4, type: Int.self),
        .init(name: .RECORD_ODO_DAY24, partType: .MainBatt, bank: 2, address: 188, length: 4, type: Int.self),
        .init(name: .UNIX_TIME_DAY25, partType: .MainBatt, bank: 2, address: 192, length: 4, type: Int.self),
        .init(name: .RECORD_ODO_DAY25, partType: .MainBatt, bank: 2, address: 196, length: 4, type: Int.self),
        .init(name: .UNIX_TIME_DAY26, partType: .MainBatt, bank: 2, address: 200, length: 4, type: Int.self),
        .init(name: .RECORD_ODO_DAY26, partType: .MainBatt, bank: 2, address: 204, length: 4, type: Int.self),
        .init(name: .UNIX_TIME_DAY27, partType: .MainBatt, bank: 2, address: 208, length: 4, type: Int.self),
        .init(name: .RECORD_ODO_DAY27, partType: .MainBatt, bank: 2, address: 212, length: 4, type: Int.self),
        .init(name: .UNIX_TIME_DAY28, partType: .MainBatt, bank: 2, address: 216, length: 4, type: Int.self),
        .init(name: .RECORD_ODO_DAY28, partType: .MainBatt, bank: 2, address: 220, length: 4, type: Int.self),
        .init(name: .UNIX_TIME_DAY29, partType: .MainBatt, bank: 2, address: 224, length: 4, type: Int.self),
        .init(name: .RECORD_ODO_DAY29, partType: .MainBatt, bank: 2, address: 228, length: 4, type: Int.self),
        .init(name: .UNIX_TIME_DAY30, partType: .MainBatt, bank: 2, address: 232, length: 4, type: Int.self),
        .init(name: .RECORD_ODO_DAY30, partType: .MainBatt, bank: 2, address: 236, length: 4, type: Int.self),
        .init(name: .UNIX_TIME_DAY31, partType: .MainBatt, bank: 2, address: 240, length: 4, type: Int.self),
        .init(name: .RECORD_ODO_DAY31, partType: .MainBatt, bank: 2, address: 244, length: 4, type: Int.self),
    ]
    
    /// 整合型的參數陣列。(基本上用於片段讀取參數)
    public var integratedParameters: [ParameterData] {
        .init([
            .init(name: .INTEGRATED_MILEAGE_RECORD, partType: .MainBatt, bank: 2, address: 0, length: 248, type: Any.self, dividedParameters: self.mileageRecordParameters),
            .init(name: .INTEGRATED_HMI_BANK0, partType: .HMI, bank: 0, address: 0, length: 202, type: Any.self, dividedParameters: self.hmiBank0Parameters),
            .init(name: .INTEGRATED_CONTROLLER_BANK0, partType: .Controller, bank: 0, address: 0, length: 202, type: Any.self, dividedParameters: self.controllerBank0Parameters),
            .init(name: .INTEGRATED_BATTERY_BANK0, partType: .MainBatt, bank: 0, address: 0, length: 202, type: Any.self, dividedParameters: self.batteryBank0Parameters),
            .init(name: .INTEGRATED_ASSIST_LEVEL, partType: .Controller, bank: 2, address: 133, length: 24, type: Any.self, dividedParameters: self.assistLevelParameters)
        ])
    }
    
    public private(set) lazy var parameters: [ParameterData] = {
        self.normalParameters + self.assistLevelParameters + self.mileageRecordParameters + self.integratedParameters
    }()
    
    /**
     透過名稱枚舉查詢部件參數。
     
     - parameter name: 名稱枚舉。
     - Returns: 目標部件的數據模型。
     - Throws: 搜尋的部件尚未定義，則拋出錯誤。
     */
    public func findParameterData(name: ParameterData.Name) throws -> ParameterData {
        let parameterData: ParameterData? = self.parameters.first(where: { $0.name == name })
        if let parameterData: ParameterData {
            return parameterData
        } else {
            throw ParameterDataRepository.Error.parameterDataNotFoundByName(name)
        }
    }
    
    /**
     透過相關資訊查詢部件參數。
     
     - parameter type: 部件參數的分類。
     - parameter bank: 部件參數的分組。
     - parameter address: 部件參數的起始位址。
     - parameter length: 部件參數的長度。
     - Returns: 目標部件的數據模型。
     - Throws: 搜尋的部件尚未定義，則拋出錯誤。
     */
    public func findParameterData(type: DeviceType_enum, bank: UInt8, address: UInt16, length: UInt16) throws -> ParameterData {
            let parameterData: ParameterData? = self.parameters.first {
                $0.partType.coreType == type && $0.bank == bank && $0.address == address && $0.length == length
            }
            if let parameterData: ParameterData {
                return parameterData
            } else {
                throw Self.Error.parameterDataNotFoundByArguments(type, bank, address, length)
            }
        }
}
