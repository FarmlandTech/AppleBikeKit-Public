//
//  ParameterData.swift
//  
//
//  Created by Yves Tsai on 2023/4/20.
//

import Foundation
import Combine

public class ParameterData: NSCopying  {
    public enum Name {
        case INTEGRATED_MILEAGE_RECORD
        case INTEGRATED_HMI_BANK0
        case INTEGRATED_BATTERY_BANK0
        case INTEGRATED_CONTROLLER_BANK0
        case INTEGRATED_ASSIST_LEVEL
        
        case HmiSMID
        case HmiDMID
        case HmiSSN
        case HmiDSN
        case HmiFrame
        case HmiSaleDate
        case HmiFWAppVer
        case HmiFWBtlVer
        case HmiFWSdkVer
        case HmiHWVer
        case HmiParaVer
        case HmiProtocolVer
        case HmiBtDevName
        case DISP_UNIT_SW
        
        case ControllerSMID
        case ControllerDMID
        case ControllerSSN
        case ControllerDSN
        case ControllerFrame
        case ControllerSaleDate
        case ControllerFWAppVer
        case ControllerFWBtlVer
        case ControllerFWSdkVer
        case ControllerHWVer
        case ControllerParaVer
        case ControllerProtocolVer
        case ControllerBtDevName
        case DISGUISE_BATT
        case INFO_ODO
        case SYS_PART_EN
        case BACKUP_ODO
        case BACKUP_LAST_TIME_ODO
        
        case BattSMID
        case BattDMID
        case BattSSN
        case BattDSN
        case BattFrame
        case BattSaleDate
        case BattFWAppVer
        case BattFWBtlVer
        case BattFWSdkVer
        case BattHWVer
        case BattParaVer
        case BattProtocolVer
        case BattBtDevName
        
        case UNIX_TIME_DAY1
        case RECORD_ODO_DAY1
        case UNIX_TIME_DAY2
        case RECORD_ODO_DAY2
        case UNIX_TIME_DAY3
        case RECORD_ODO_DAY3
        case UNIX_TIME_DAY4
        case RECORD_ODO_DAY4
        case UNIX_TIME_DAY5
        case RECORD_ODO_DAY5
        case UNIX_TIME_DAY6
        case RECORD_ODO_DAY6
        case UNIX_TIME_DAY7
        case RECORD_ODO_DAY7
        case UNIX_TIME_DAY8
        case RECORD_ODO_DAY8
        case UNIX_TIME_DAY9
        case RECORD_ODO_DAY9
        case UNIX_TIME_DAY10
        case RECORD_ODO_DAY10
        case UNIX_TIME_DAY11
        case RECORD_ODO_DAY11
        case UNIX_TIME_DAY12
        case RECORD_ODO_DAY12
        case UNIX_TIME_DAY13
        case RECORD_ODO_DAY13
        case UNIX_TIME_DAY14
        case RECORD_ODO_DAY14
        case UNIX_TIME_DAY15
        case RECORD_ODO_DAY15
        case UNIX_TIME_DAY16
        case RECORD_ODO_DAY16
        case UNIX_TIME_DAY17
        case RECORD_ODO_DAY17
        case UNIX_TIME_DAY18
        case RECORD_ODO_DAY18
        case UNIX_TIME_DAY19
        case RECORD_ODO_DAY19
        case UNIX_TIME_DAY20
        case RECORD_ODO_DAY20
        case UNIX_TIME_DAY21
        case RECORD_ODO_DAY21
        case UNIX_TIME_DAY22
        case RECORD_ODO_DAY22
        case UNIX_TIME_DAY23
        case RECORD_ODO_DAY23
        case UNIX_TIME_DAY24
        case RECORD_ODO_DAY24
        case UNIX_TIME_DAY25
        case RECORD_ODO_DAY25
        case UNIX_TIME_DAY26
        case RECORD_ODO_DAY26
        case UNIX_TIME_DAY27
        case RECORD_ODO_DAY27
        case UNIX_TIME_DAY28
        case RECORD_ODO_DAY28
        case UNIX_TIME_DAY29
        case RECORD_ODO_DAY29
        case UNIX_TIME_DAY30
        case RECORD_ODO_DAY30
        case UNIX_TIME_DAY31
        case RECORD_ODO_DAY31
        
        case LV1_MAX_AST_RATIO
        case LV1_MIN_AST_RATIO
        case LV1_AST_RATIO_STR_SPD
        case LV1_AST_RATIO_END_SPD
        case LV2_MAX_AST_RATIO
        case LV2_MIN_AST_RATIO
        case LV2_AST_RATIO_STR_SPD
        case LV2_AST_RATIO_END_SPD
        case LV3_MAX_AST_RATIO
        case LV3_MIN_AST_RATIO
        case LV3_AST_RATIO_STR_SPD
        case LV3_AST_RATIO_END_SPD
    }
    
    public private(set) var name: ParameterData.Name
    public private(set) var partType: CommunicationPartType
    public private(set) var bank: UInt8
    public private(set) var address: UInt16
    public private(set) var length: UInt16
    public private(set) var type: Any
    // 目前 var value: Any? 與 var subject: CurrentValueSubject<Any?, Never> 的存在，有相當程度的重複性
    // ，但因為早期規劃，暫時先保留，後面的版本在優化參數架構。
    public var value: Any?
    public private(set) var subject: CurrentValueSubject<Any?, Never> = .init(nil)
    
    private var _dividedParameters: [ParameterData]?
    public var dividedParameters: [ParameterData]? {
        self._dividedParameters
    }
    
    public init(name: ParameterData.Name, partType: CommunicationPartType, bank: UInt8, address: UInt16, length: UInt16, type: Any, value: Any? = nil, dividedParameters: [ParameterData]? = nil) {
        self.name = name
        self.partType = partType
        self.bank = bank
        self.address = address
        self.length = length
        self.type = type
        self.value = value
        self._dividedParameters = dividedParameters
    }
    
    public func copy(with zone: NSZone? = nil) -> Any {
        ParameterData(name: self.name,
                      partType: self.partType,
                      bank: self.bank,
                      address: self.address,
                      length: self.length,
                      type: self.type)
    }
}
