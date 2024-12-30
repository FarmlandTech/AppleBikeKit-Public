//
//  AppleParameterDataRepository.swift
//  
//
//  Created by Yves Tsai on 2024/3/27.
//

import Foundation

import CoreSDKService

public class AppleParameterDataRepository: BaseParameterDataRepository, ParameterDataSource {
    
    public let hmiBank0Parameters: [ParameterData] = [
        .init(name: ParameterData.Apple.Name.HmiSMID.rawValue, partType: .HMI, bank: 0, address: 0, length: 15, type: String.self),
        .init(name: ParameterData.Apple.Name.HmiDMID.rawValue, partType: .HMI, bank: 0, address: 15, length: 17, type: String.self),
        .init(name: ParameterData.Apple.Name.HmiSSN.rawValue, partType: .HMI, bank: 0, address: 32, length: 32, type: String.self),
        .init(name: ParameterData.Apple.Name.HmiDSN.rawValue, partType: .HMI, bank: 0, address: 64, length: 32, type: String.self),
        .init(name: ParameterData.Apple.Name.HmiFrame.rawValue, partType: .HMI, bank: 0, address: 96, length: 32, type: String.self),
        .init(name: ParameterData.Apple.Name.HmiSaleDate.rawValue, partType: .HMI, bank: 0, address: 128, length: 6, type: String.self),
        .init(name: ParameterData.Apple.Name.HmiFWAppVer.rawValue, partType: .HMI, bank: 0, address: 134, length: 6, type: String.self),
        .init(name: ParameterData.Apple.Name.HmiFWBtlVer.rawValue, partType: .HMI, bank: 0, address: 140, length: 6, type: String.self),
        .init(name: ParameterData.Apple.Name.HmiFWSdkVer.rawValue, partType: .HMI, bank: 0, address: 146, length: 6, type: String.self),
        .init(name: ParameterData.Apple.Name.HmiHWVer.rawValue, partType: .HMI, bank: 0, address: 152, length: 11, type: String.self),
        .init(name: ParameterData.Apple.Name.HmiParaVer.rawValue, partType: .HMI, bank: 0, address: 163, length: 6, type: String.self),
        .init(name: ParameterData.Apple.Name.HmiProtocolVer.rawValue, partType: .HMI, bank: 0, address: 169, length: 11, type: String.self),
        .init(name: ParameterData.Apple.Name.HmiBtDevName.rawValue, partType: .HMI, bank: 0, address: 180, length: 22, type: String.self)
    ]
    
    public let hmiBank1Parameters: [ParameterData] = []
    
    public let hmiBank2Parameters: [ParameterData] = [
        .init(name: ParameterData.Apple.Name.DISP_UNIT_SW.rawValue, partType: .HMI, bank: 2, address: 153, length: 1, type: Int.self),
        .init(name: ParameterData.Apple.Name.HmiErrorLimit.rawValue, partType: .HMI, bank: 2, address: 310, length: 1, type: Int.self),
        .init(name: ParameterData.Apple.Name.HmiErrorCount.rawValue, partType: .HMI, bank: 2, address: 311, length: 1, type: Int.self)
    ]
    
    public let controllerBank0Parameters: [ParameterData] = [
        .init(name: ParameterData.Apple.Name.ControllerSMID.rawValue, partType: .Controller, bank: 0, address: 0, length: 15, type: String.self),
        .init(name: ParameterData.Apple.Name.ControllerDMID.rawValue, partType: .Controller, bank: 0, address: 15, length: 17, type: String.self),
        .init(name: ParameterData.Apple.Name.ControllerSSN.rawValue, partType: .Controller, bank: 0, address: 32, length: 32, type: String.self),
        .init(name: ParameterData.Apple.Name.ControllerDSN.rawValue, partType: .Controller, bank: 0, address: 64, length: 32, type: String.self),
        .init(name: ParameterData.Apple.Name.ControllerFrame.rawValue, partType: .Controller, bank: 0, address: 96, length: 32, type: String.self),
        .init(name: ParameterData.Apple.Name.ControllerSaleDate.rawValue, partType: .Controller, bank: 0, address: 128, length: 6, type: String.self),
        .init(name: ParameterData.Apple.Name.ControllerFWAppVer.rawValue, partType: .Controller, bank: 0, address: 134, length: 6, type: String.self),
        .init(name: ParameterData.Apple.Name.ControllerFWBtlVer.rawValue, partType: .Controller, bank: 0, address: 140, length: 6, type: String.self),
        .init(name: ParameterData.Apple.Name.ControllerFWSdkVer.rawValue, partType: .Controller, bank: 0, address: 146, length: 6, type: String.self),
        .init(name: ParameterData.Apple.Name.ControllerHWVer.rawValue, partType: .Controller, bank: 0, address: 152, length: 11, type: String.self),
        .init(name: ParameterData.Apple.Name.ControllerParaVer.rawValue, partType: .Controller, bank: 0, address: 163, length: 6, type: String.self),
        .init(name: ParameterData.Apple.Name.ControllerProtocolVer.rawValue, partType: .Controller, bank: 0, address: 169, length: 11, type: String.self),
        .init(name: ParameterData.Apple.Name.ControllerBtDevName.rawValue, partType: .Controller, bank: 0, address: 180, length: 22, type: String.self),
    ]
    
    public let controllerBank1Parameters: [ParameterData] = [
        .init(name: ParameterData.Apple.Name.DISGUISE_BATT.rawValue, partType: .Controller, bank: 1, address: 0, length: 1, type: Int.self),
        .init(name: ParameterData.Apple.Name.INFO_ODO.rawValue, partType: .Controller, bank: 1, address: 217, length: 4, type: Int.self),
    ]
    
    public let controllerBank2Parameters: [ParameterData] = [
        .init(name: ParameterData.Apple.Name.SYS_PART_EN.rawValue, partType: .Controller, bank: 2, address: 358, length: 4, type: [UInt8].self),
    ]
    
    public let controllerBank3Parameters: [ParameterData] = [
        .init(name: ParameterData.Apple.Name.BACKUP_ODO.rawValue, partType: .Controller, bank: 2, address: 128, length: 4, type: Int.self),
        .init(name: ParameterData.Apple.Name.BACKUP_LAST_TIME_ODO.rawValue, partType: .Controller, bank: 2, address: 148, length: 4, type: Int.self)
    ]
    
    public let batteryBank0Parameters: [ParameterData] = [
        .init(name: ParameterData.Apple.Name.BattSMID.rawValue, partType: .MainBatt, bank: 0, address: 0, length: 15, type: String.self),
        .init(name: ParameterData.Apple.Name.BattDMID.rawValue, partType: .MainBatt, bank: 0, address: 15, length: 17, type: String.self),
        .init(name: ParameterData.Apple.Name.BattSSN.rawValue, partType: .MainBatt, bank: 0, address: 32, length: 32, type: String.self),
        .init(name: ParameterData.Apple.Name.BattDSN.rawValue, partType: .MainBatt, bank: 0, address: 64, length: 32, type: String.self),
        .init(name: ParameterData.Apple.Name.BattFrame.rawValue, partType: .MainBatt, bank: 0, address: 96, length: 32, type: String.self),
        .init(name: ParameterData.Apple.Name.BattSaleDate.rawValue, partType: .MainBatt, bank: 0, address: 128, length: 6, type: String.self),
        .init(name: ParameterData.Apple.Name.BattFWAppVer.rawValue, partType: .MainBatt, bank: 0, address: 134, length: 6, type: String.self),
        .init(name: ParameterData.Apple.Name.BattFWBtlVer.rawValue, partType: .MainBatt, bank: 0, address: 140, length: 6, type: String.self),
        .init(name: ParameterData.Apple.Name.BattFWSdkVer.rawValue, partType: .MainBatt, bank: 0, address: 146, length: 6, type: String.self),
        .init(name: ParameterData.Apple.Name.BattHWVer.rawValue, partType: .MainBatt, bank: 0, address: 152, length: 11, type: String.self),
        .init(name: ParameterData.Apple.Name.BattParaVer.rawValue, partType: .MainBatt, bank: 0, address: 163, length: 6, type: String.self),
        .init(name: ParameterData.Apple.Name.BattProtocolVer.rawValue, partType: .MainBatt, bank: 0, address: 169, length: 11, type: String.self),
        .init(name: ParameterData.Apple.Name.BattBtDevName.rawValue, partType: .MainBatt, bank: 0, address: 180, length: 22, type: String.self),
    ]
    
    /// 基礎部件的關鍵參數陣列。(應再根據類別再次拆分)
    public private(set) lazy var normalParameters: [ParameterData] = {
        self.hmiBank0Parameters +
        [.init(name: ParameterData.Apple.Name.HmiSvrToken.rawValue, partType: .HMI, bank: 0, address: 365, length: 32, type: String.self)] +
        self.hmiBank2Parameters +
        self.controllerBank0Parameters +
        self.controllerBank1Parameters +
        self.controllerBank2Parameters +
        self.controllerBank3Parameters +
        self.batteryBank0Parameters
    }()
    
    /// 助力方案相關的參數陣列。
    public let assistLevelParameters:[ParameterData] = [
        .init(name: ParameterData.Apple.Name.LV1_MAX_AST_RATIO.rawValue, partType: .Controller, bank: 2, address: 133, length: 2, type: Int.self),
        .init(name: ParameterData.Apple.Name.LV1_MIN_AST_RATIO.rawValue, partType: .Controller, bank: 2, address: 135, length: 2, type: Int.self),
        .init(name: ParameterData.Apple.Name.LV1_AST_RATIO_STR_SPD.rawValue, partType: .Controller, bank: 2, address: 137, length: 2, type: Int.self),
        .init(name: ParameterData.Apple.Name.LV1_AST_RATIO_END_SPD.rawValue, partType: .Controller, bank: 2, address: 139, length: 2, type: Int.self),
        .init(name: ParameterData.Apple.Name.LV2_MAX_AST_RATIO.rawValue, partType: .Controller, bank: 2, address: 141, length: 2, type: Int.self),
        .init(name: ParameterData.Apple.Name.LV2_MIN_AST_RATIO.rawValue, partType: .Controller, bank: 2, address: 143, length: 2, type: Int.self),
        .init(name: ParameterData.Apple.Name.LV2_AST_RATIO_STR_SPD.rawValue, partType: .Controller, bank: 2, address: 145, length: 2, type: Int.self),
        .init(name: ParameterData.Apple.Name.LV2_AST_RATIO_END_SPD.rawValue, partType: .Controller, bank: 2, address: 147, length: 2, type: Int.self),
        .init(name: ParameterData.Apple.Name.LV3_MAX_AST_RATIO.rawValue, partType: .Controller, bank: 2, address: 149, length: 2, type: Int.self),
        .init(name: ParameterData.Apple.Name.LV3_MIN_AST_RATIO.rawValue, partType: .Controller, bank: 2, address: 151, length: 2, type: Int.self),
        .init(name: ParameterData.Apple.Name.LV3_AST_RATIO_STR_SPD.rawValue, partType: .Controller, bank: 2, address: 153, length: 2, type: Int.self),
        .init(name: ParameterData.Apple.Name.LV3_AST_RATIO_END_SPD.rawValue, partType: .Controller, bank: 2, address: 155, length: 2, type: Int.self),
    ]
    
    /// 里程相關的參數陣列。
    public let mileageRecordParameters: [ParameterData] = [
        .init(name: ParameterData.Apple.Name.UNIX_TIME_DAY1.rawValue, partType: .MainBatt, bank: 2, address: 0, length: 4, type: Int.self),
        .init(name: ParameterData.Apple.Name.RECORD_ODO_DAY1.rawValue, partType: .MainBatt, bank: 2, address: 4, length: 4, type: Int.self),
        .init(name: ParameterData.Apple.Name.UNIX_TIME_DAY2.rawValue, partType: .MainBatt, bank: 2, address: 8, length: 4, type: Int.self),
        .init(name: ParameterData.Apple.Name.RECORD_ODO_DAY2.rawValue, partType: .MainBatt, bank: 2, address: 12, length: 4, type: Int.self),
        .init(name: ParameterData.Apple.Name.UNIX_TIME_DAY3.rawValue, partType: .MainBatt, bank: 2, address: 16, length: 4, type: Int.self),
        .init(name: ParameterData.Apple.Name.RECORD_ODO_DAY3.rawValue, partType: .MainBatt, bank: 2, address: 20, length: 4, type: Int.self),
        .init(name: ParameterData.Apple.Name.UNIX_TIME_DAY4.rawValue, partType: .MainBatt, bank: 2, address: 24, length: 4, type: Int.self),
        .init(name: ParameterData.Apple.Name.RECORD_ODO_DAY4.rawValue, partType: .MainBatt, bank: 2, address: 28, length: 4, type: Int.self),
        .init(name: ParameterData.Apple.Name.UNIX_TIME_DAY5.rawValue, partType: .MainBatt, bank: 2, address: 32, length: 4, type: Int.self),
        .init(name: ParameterData.Apple.Name.RECORD_ODO_DAY5.rawValue, partType: .MainBatt, bank: 2, address: 36, length: 4, type: Int.self),
        .init(name: ParameterData.Apple.Name.UNIX_TIME_DAY6.rawValue, partType: .MainBatt, bank: 2, address: 40, length: 4, type: Int.self),
        .init(name: ParameterData.Apple.Name.RECORD_ODO_DAY6.rawValue, partType: .MainBatt, bank: 2, address: 44, length: 4, type: Int.self),
        .init(name: ParameterData.Apple.Name.UNIX_TIME_DAY7.rawValue, partType: .MainBatt, bank: 2, address: 48, length: 4, type: Int.self),
        .init(name: ParameterData.Apple.Name.RECORD_ODO_DAY7.rawValue, partType: .MainBatt, bank: 2, address: 52, length: 4, type: Int.self),
        .init(name: ParameterData.Apple.Name.UNIX_TIME_DAY8.rawValue, partType: .MainBatt, bank: 2, address: 56, length: 4, type: Int.self),
        .init(name: ParameterData.Apple.Name.RECORD_ODO_DAY8.rawValue, partType: .MainBatt, bank: 2, address: 60, length: 4, type: Int.self),
        .init(name: ParameterData.Apple.Name.UNIX_TIME_DAY9.rawValue, partType: .MainBatt, bank: 2, address: 64, length: 4, type: Int.self),
        .init(name: ParameterData.Apple.Name.RECORD_ODO_DAY9.rawValue, partType: .MainBatt, bank: 2, address: 68, length: 4, type: Int.self),
        .init(name: ParameterData.Apple.Name.UNIX_TIME_DAY10.rawValue, partType: .MainBatt, bank: 2, address: 72, length: 4, type: Int.self),
        .init(name: ParameterData.Apple.Name.RECORD_ODO_DAY10.rawValue, partType: .MainBatt, bank: 2, address: 76, length: 4, type: Int.self),
        .init(name: ParameterData.Apple.Name.UNIX_TIME_DAY11.rawValue, partType: .MainBatt, bank: 2, address: 80, length: 4, type: Int.self),
        .init(name: ParameterData.Apple.Name.RECORD_ODO_DAY11.rawValue, partType: .MainBatt, bank: 2, address: 84, length: 4, type: Int.self),
        .init(name: ParameterData.Apple.Name.UNIX_TIME_DAY12.rawValue, partType: .MainBatt, bank: 2, address: 88, length: 4, type: Int.self),
        .init(name: ParameterData.Apple.Name.RECORD_ODO_DAY12.rawValue, partType: .MainBatt, bank: 2, address: 92, length: 4, type: Int.self),
        .init(name: ParameterData.Apple.Name.UNIX_TIME_DAY13.rawValue, partType: .MainBatt, bank: 2, address: 96, length: 4, type: Int.self),
        .init(name: ParameterData.Apple.Name.RECORD_ODO_DAY13.rawValue, partType: .MainBatt, bank: 2, address: 100, length: 4, type: Int.self),
        .init(name: ParameterData.Apple.Name.UNIX_TIME_DAY14.rawValue, partType: .MainBatt, bank: 2, address: 104, length: 4, type: Int.self),
        .init(name: ParameterData.Apple.Name.RECORD_ODO_DAY14.rawValue, partType: .MainBatt, bank: 2, address: 108, length: 4, type: Int.self),
        .init(name: ParameterData.Apple.Name.UNIX_TIME_DAY15.rawValue, partType: .MainBatt, bank: 2, address: 112, length: 4, type: Int.self),
        .init(name: ParameterData.Apple.Name.RECORD_ODO_DAY15.rawValue, partType: .MainBatt, bank: 2, address: 116, length: 4, type: Int.self),
        .init(name: ParameterData.Apple.Name.UNIX_TIME_DAY16.rawValue, partType: .MainBatt, bank: 2, address: 120, length: 4, type: Int.self),
        .init(name: ParameterData.Apple.Name.RECORD_ODO_DAY16.rawValue, partType: .MainBatt, bank: 2, address: 124, length: 4, type: Int.self),
        .init(name: ParameterData.Apple.Name.UNIX_TIME_DAY17.rawValue, partType: .MainBatt, bank: 2, address: 128, length: 4, type: Int.self),
        .init(name: ParameterData.Apple.Name.RECORD_ODO_DAY17.rawValue, partType: .MainBatt, bank: 2, address: 132, length: 4, type: Int.self),
        .init(name: ParameterData.Apple.Name.UNIX_TIME_DAY18.rawValue, partType: .MainBatt, bank: 2, address: 136, length: 4, type: Int.self),
        .init(name: ParameterData.Apple.Name.RECORD_ODO_DAY18.rawValue, partType: .MainBatt, bank: 2, address: 140, length: 4, type: Int.self),
        .init(name: ParameterData.Apple.Name.UNIX_TIME_DAY19.rawValue, partType: .MainBatt, bank: 2, address: 144, length: 4, type: Int.self),
        .init(name: ParameterData.Apple.Name.RECORD_ODO_DAY19.rawValue, partType: .MainBatt, bank: 2, address: 148, length: 4, type: Int.self),
        .init(name: ParameterData.Apple.Name.UNIX_TIME_DAY20.rawValue, partType: .MainBatt, bank: 2, address: 152, length: 4, type: Int.self),
        .init(name: ParameterData.Apple.Name.RECORD_ODO_DAY20.rawValue, partType: .MainBatt, bank: 2, address: 156, length: 4, type: Int.self),
        .init(name: ParameterData.Apple.Name.UNIX_TIME_DAY21.rawValue, partType: .MainBatt, bank: 2, address: 160, length: 4, type: Int.self),
        .init(name: ParameterData.Apple.Name.RECORD_ODO_DAY21.rawValue, partType: .MainBatt, bank: 2, address: 164, length: 4, type: Int.self),
        .init(name: ParameterData.Apple.Name.UNIX_TIME_DAY22.rawValue, partType: .MainBatt, bank: 2, address: 168, length: 4, type: Int.self),
        .init(name: ParameterData.Apple.Name.RECORD_ODO_DAY22.rawValue, partType: .MainBatt, bank: 2, address: 172, length: 4, type: Int.self),
        .init(name: ParameterData.Apple.Name.UNIX_TIME_DAY23.rawValue, partType: .MainBatt, bank: 2, address: 176, length: 4, type: Int.self),
        .init(name: ParameterData.Apple.Name.RECORD_ODO_DAY23.rawValue, partType: .MainBatt, bank: 2, address: 180, length: 4, type: Int.self),
        .init(name: ParameterData.Apple.Name.UNIX_TIME_DAY24.rawValue, partType: .MainBatt, bank: 2, address: 184, length: 4, type: Int.self),
        .init(name: ParameterData.Apple.Name.RECORD_ODO_DAY24.rawValue, partType: .MainBatt, bank: 2, address: 188, length: 4, type: Int.self),
        .init(name: ParameterData.Apple.Name.UNIX_TIME_DAY25.rawValue, partType: .MainBatt, bank: 2, address: 192, length: 4, type: Int.self),
        .init(name: ParameterData.Apple.Name.RECORD_ODO_DAY25.rawValue, partType: .MainBatt, bank: 2, address: 196, length: 4, type: Int.self),
        .init(name: ParameterData.Apple.Name.UNIX_TIME_DAY26.rawValue, partType: .MainBatt, bank: 2, address: 200, length: 4, type: Int.self),
        .init(name: ParameterData.Apple.Name.RECORD_ODO_DAY26.rawValue, partType: .MainBatt, bank: 2, address: 204, length: 4, type: Int.self),
        .init(name: ParameterData.Apple.Name.UNIX_TIME_DAY27.rawValue, partType: .MainBatt, bank: 2, address: 208, length: 4, type: Int.self),
        .init(name: ParameterData.Apple.Name.RECORD_ODO_DAY27.rawValue, partType: .MainBatt, bank: 2, address: 212, length: 4, type: Int.self),
        .init(name: ParameterData.Apple.Name.UNIX_TIME_DAY28.rawValue, partType: .MainBatt, bank: 2, address: 216, length: 4, type: Int.self),
        .init(name: ParameterData.Apple.Name.RECORD_ODO_DAY28.rawValue, partType: .MainBatt, bank: 2, address: 220, length: 4, type: Int.self),
        .init(name: ParameterData.Apple.Name.UNIX_TIME_DAY29.rawValue, partType: .MainBatt, bank: 2, address: 224, length: 4, type: Int.self),
        .init(name: ParameterData.Apple.Name.RECORD_ODO_DAY29.rawValue, partType: .MainBatt, bank: 2, address: 228, length: 4, type: Int.self),
        .init(name: ParameterData.Apple.Name.UNIX_TIME_DAY30.rawValue, partType: .MainBatt, bank: 2, address: 232, length: 4, type: Int.self),
        .init(name: ParameterData.Apple.Name.RECORD_ODO_DAY30.rawValue, partType: .MainBatt, bank: 2, address: 236, length: 4, type: Int.self),
        .init(name: ParameterData.Apple.Name.UNIX_TIME_DAY31.rawValue, partType: .MainBatt, bank: 2, address: 240, length: 4, type: Int.self),
        .init(name: ParameterData.Apple.Name.RECORD_ODO_DAY31.rawValue, partType: .MainBatt, bank: 2, address: 244, length: 4, type: Int.self),
    ]
    
    ///
    public let pedalAssistanceParameters: [ParameterData] = [
        .init(name: ParameterData.Apple.Name.Controller_P_STR_MAX_DEG.rawValue, partType: .Controller, bank: 2, address: 115, length: 2, type: Int.self),
        .init(name: ParameterData.Apple.Name.Controller_P_STR_MIN_DEG.rawValue, partType: .Controller, bank: 2, address: 117, length: 2, type: Int.self),
        .init(name: ParameterData.Apple.Name.Controller_P_STR_MAX_TORQ.rawValue, partType: .Controller, bank: 2, address: 119, length: 1, type: Int.self),
        .init(name: ParameterData.Apple.Name.Controller_P_STR_MIN_TORQ.rawValue, partType: .Controller, bank: 2, address: 120, length: 1, type: Int.self),
        .init(name: ParameterData.Apple.Name.Controller_P_STR_STR_SPD.rawValue, partType: .Controller, bank: 2, address: 121, length: 2, type: Int.self),
        .init(name: ParameterData.Apple.Name.Controller_P_STR_END_SPD.rawValue, partType: .Controller, bank: 2, address: 123, length: 2, type: Int.self),
        .init(name: ParameterData.Apple.Name.Controller_P_STOP_MAX_CAD_SPD.rawValue, partType: .Controller, bank: 2, address: 125, length: 1, type: Int.self),
        .init(name: ParameterData.Apple.Name.Controller_P_STOP_MIN_CAD_SPD.rawValue, partType: .Controller, bank: 2, address: 126, length: 1, type: Int.self),
        .init(name: ParameterData.Apple.Name.Controller_P_STOP_STR_SPD.rawValue, partType: .Controller, bank: 2, address: 127, length: 2, type: Int.self),
        .init(name: ParameterData.Apple.Name.Controller_P_STOP_END_SPD.rawValue, partType: .Controller, bank: 2, address: 129, length: 2, type: Int.self),
        .init(name: ParameterData.Apple.Name.Controller_P_AST_LV1_STR_RANG.rawValue, partType: .Controller, bank: 2, address: 131, length: 2, type: Int.self),
        .init(name: ParameterData.Apple.Name.Controller_P_LV1_MAX_AST_RATIO.rawValue, partType: .Controller, bank: 2, address: 133, length: 2, type: Int.self),
        .init(name: ParameterData.Apple.Name.Controller_P_LV1_MIN_AST_RATIO.rawValue, partType: .Controller, bank: 2, address: 135, length: 2, type: Int.self),
        .init(name: ParameterData.Apple.Name.Controller_P_LV1_AST_RATIO_STR_SPD.rawValue, partType: .Controller, bank: 2, address: 137, length: 2, type: Int.self),
        .init(name: ParameterData.Apple.Name.Controller_P_LV1_AST_RATIO_END_SPD.rawValue, partType: .Controller, bank: 2, address: 139, length: 2, type: Int.self),
        .init(name: ParameterData.Apple.Name.Controller_P_LV2_MAX_AST_RATIO.rawValue, partType: .Controller, bank: 2, address: 141, length: 2, type: Int.self),
        .init(name: ParameterData.Apple.Name.Controller_P_LV2_MIN_AST_RATIO.rawValue, partType: .Controller, bank: 2, address: 143, length: 2, type: Int.self),
        .init(name: ParameterData.Apple.Name.Controller_P_LV2_AST_RATIO_STR_SPD.rawValue, partType: .Controller, bank: 2, address: 145, length: 2, type: Int.self),
        .init(name: ParameterData.Apple.Name.Controller_P_LV2_AST_RATIO_END_SPD.rawValue, partType: .Controller, bank: 2, address: 147, length: 2, type: Int.self),
        .init(name: ParameterData.Apple.Name.Controller_P_LV3_MAX_AST_RATIO.rawValue, partType: .Controller, bank: 2, address: 149, length: 2, type: Int.self),
        .init(name: ParameterData.Apple.Name.Controller_P_LV3_MIN_AST_RATIO.rawValue, partType: .Controller, bank: 2, address: 151, length: 2, type: Int.self),
        .init(name: ParameterData.Apple.Name.Controller_P_LV3_AST_RATIO_STR_SPD.rawValue, partType: .Controller, bank: 2, address: 153, length: 2, type: Int.self),
        .init(name: ParameterData.Apple.Name.Controller_P_LV3_AST_RATIO_END_SPD.rawValue, partType: .Controller, bank: 2, address: 155, length: 2, type: Int.self),
        .init(name: ParameterData.Apple.Name.Controller_P_LV4_MAX_AST_RATIO.rawValue, partType: .Controller, bank: 2, address: 157, length: 2, type: Int.self),
        .init(name: ParameterData.Apple.Name.Controller_P_LV4_MIN_AST_RATIO.rawValue, partType: .Controller, bank: 2, address: 159, length: 2, type: Int.self),
        .init(name: ParameterData.Apple.Name.Controller_P_LV4_AST_RATIO_STR_SPD.rawValue, partType: .Controller, bank: 2, address: 161, length: 2, type: Int.self),
        .init(name: ParameterData.Apple.Name.Controller_P_LV4_AST_RATIO_END_SPD.rawValue, partType: .Controller, bank: 2, address: 163, length: 2, type: Int.self),
        .init(name: ParameterData.Apple.Name.Controller_P_LV5_MAX_AST_RATIO.rawValue, partType: .Controller, bank: 2, address: 165, length: 2, type: Int.self),
        .init(name: ParameterData.Apple.Name.Controller_P_LV5_MIN_AST_RATIO.rawValue, partType: .Controller, bank: 2, address: 167, length: 2, type: Int.self),
        .init(name: ParameterData.Apple.Name.Controller_P_LV5_AST_RATIO_STR_SPD.rawValue, partType: .Controller, bank: 2, address: 169, length: 2, type: Int.self),
        .init(name: ParameterData.Apple.Name.Controller_P_LV5_AST_RATIO_END_SPD.rawValue, partType: .Controller, bank: 2, address: 171, length: 2, type: Int.self),
        .init(name: ParameterData.Apple.Name.Controller_P_AST_CTRL_FREQ.rawValue, partType: .Controller, bank: 2, address: 173, length: 2, type: Int.self),
        .init(name: ParameterData.Apple.Name.Controller_P_AST_LV1_STR_ACC.rawValue, partType: .Controller, bank: 2, address: 175, length: 1, type: Int.self),
        .init(name: ParameterData.Apple.Name.Controller_P_AST_LV1_STR_DEC.rawValue, partType: .Controller, bank: 2, address: 176, length: 1, type: Int.self),
        .init(name: ParameterData.Apple.Name.Controller_P_AST_LV1_MAX_CUR.rawValue, partType: .Controller, bank: 2, address: 177, length: 2, type: Int.self),
        .init(name: ParameterData.Apple.Name.Controller_P_AST_LV1_ACC.rawValue, partType: .Controller, bank: 2, address: 179, length: 1, type: Int.self),
        .init(name: ParameterData.Apple.Name.Controller_P_AST_LV1_DEC.rawValue, partType: .Controller, bank: 2, address: 180, length: 1, type: Int.self),
        .init(name: ParameterData.Apple.Name.Controller_P_AST_LV2_MAX_CUR.rawValue, partType: .Controller, bank: 2, address: 181, length: 2, type: Int.self),
        .init(name: ParameterData.Apple.Name.Controller_P_AST_LV2_ACC.rawValue, partType: .Controller, bank: 2, address: 183, length: 1, type: Int.self),
        .init(name: ParameterData.Apple.Name.Controller_P_AST_LV2_DEC.rawValue, partType: .Controller, bank: 2, address: 184, length: 1, type: Int.self),
        .init(name: ParameterData.Apple.Name.Controller_P_AST_LV3_MAX_CUR.rawValue, partType: .Controller, bank: 2, address: 185, length: 2, type: Int.self),
        .init(name: ParameterData.Apple.Name.Controller_P_AST_LV3_ACC.rawValue, partType: .Controller, bank: 2, address: 187, length: 1, type: Int.self),
        .init(name: ParameterData.Apple.Name.Controller_P_AST_LV3_DEC.rawValue, partType: .Controller, bank: 2, address: 188, length: 1, type: Int.self),
        .init(name: ParameterData.Apple.Name.Controller_P_AST_LV4_MAX_CUR.rawValue, partType: .Controller, bank: 2, address: 189, length: 2, type: Int.self),
        .init(name: ParameterData.Apple.Name.Controller_P_AST_LV4_ACC.rawValue, partType: .Controller, bank: 2, address: 191, length: 1, type: Int.self),
        .init(name: ParameterData.Apple.Name.Controller_P_AST_LV4_DEC.rawValue, partType: .Controller, bank: 2, address: 192, length: 1, type: Int.self),
        .init(name: ParameterData.Apple.Name.Controller_P_AST_LV5_MAX_CUR.rawValue, partType: .Controller, bank: 2, address: 193, length: 2, type: Int.self),
        .init(name: ParameterData.Apple.Name.Controller_P_AST_LV5_ACC.rawValue, partType: .Controller, bank: 2, address: 195, length: 1, type: Int.self),
        .init(name: ParameterData.Apple.Name.Controller_P_AST_LV5_DEC.rawValue, partType: .Controller, bank: 2, address: 196, length: 1, type: Int.self),
        .init(name: ParameterData.Apple.Name.Controller_P_AST_OSP_DEC.rawValue, partType: .Controller, bank: 2, address: 197, length: 1, type: Int.self),
        .init(name: ParameterData.Apple.Name.Controller_P_AST_OCP_DEC.rawValue, partType: .Controller, bank: 2, address: 198, length: 1, type: Int.self),
        .init(name: ParameterData.Apple.Name.Controller_P_AST_STOP_DEC.rawValue, partType: .Controller, bank: 2, address: 199, length: 1, type: Int.self),
        .init(name: ParameterData.Apple.Name.Controller_P_AST_LV2_STR_RANG.rawValue, partType: .Controller, bank: 2, address: 200, length: 2, type: Int.self),
        .init(name: ParameterData.Apple.Name.Controller_P_AST_LV3_STR_RANG.rawValue, partType: .Controller, bank: 2, address: 202, length: 2, type: Int.self),
        .init(name: ParameterData.Apple.Name.Controller_P_AST_LV4_STR_RANG.rawValue, partType: .Controller, bank: 2, address: 204, length: 2, type: Int.self),
        .init(name: ParameterData.Apple.Name.Controller_P_AST_LV5_STR_RANG.rawValue, partType: .Controller, bank: 2, address: 206, length: 2, type: Int.self),
        .init(name: ParameterData.Apple.Name.Controller_P_AST_LV2_STR_ACC.rawValue, partType: .Controller, bank: 2, address: 208, length: 1, type: Int.self),
        .init(name: ParameterData.Apple.Name.Controller_P_AST_LV2_STR_DEC.rawValue, partType: .Controller, bank: 2, address: 209, length: 1, type: Int.self),
        .init(name: ParameterData.Apple.Name.Controller_P_AST_LV3_STR_ACC.rawValue, partType: .Controller, bank: 2, address: 210, length: 1, type: Int.self),
        .init(name: ParameterData.Apple.Name.Controller_P_AST_LV3_STR_DEC.rawValue, partType: .Controller, bank: 2, address: 211, length: 1, type: Int.self),
        .init(name: ParameterData.Apple.Name.Controller_P_AST_LV4_STR_ACC.rawValue, partType: .Controller, bank: 2, address: 212, length: 1, type: Int.self),
        .init(name: ParameterData.Apple.Name.Controller_P_AST_LV4_STR_DEC.rawValue, partType: .Controller, bank: 2, address: 213, length: 1, type: Int.self),
        .init(name: ParameterData.Apple.Name.Controller_P_AST_LV5_STR_ACC.rawValue, partType: .Controller, bank: 2, address: 214, length: 1, type: Int.self),
        .init(name: ParameterData.Apple.Name.Controller_P_AST_LV5_STR_DEC.rawValue, partType: .Controller, bank: 2, address: 215, length: 1, type: Int.self),
        .init(name: ParameterData.Apple.Name.Controller_P_AST_BRAKE_DEC.rawValue, partType: .Controller, bank: 2, address: 216, length: 1, type: Int.self),
        .init(name: ParameterData.Apple.Name.Controller_P_AST_LIM_CUR_DEC.rawValue, partType: .Controller, bank: 2, address: 217, length: 1, type: Int.self),
    ]
    
    public let himAccessControlParameters: [ParameterData] = [
        .init(name: ParameterData.Apple.Name.HmiPasswordCode1.rawValue, partType: .HMI, bank: 2, address: 306, length: 1, type: Int.self),
        .init(name: ParameterData.Apple.Name.HmiPasswordCode2.rawValue, partType: .HMI, bank: 2, address: 307, length: 1, type: Int.self),
        .init(name: ParameterData.Apple.Name.HmiPasswordCode3.rawValue, partType: .HMI, bank: 2, address: 308, length: 1, type: Int.self),
        .init(name: ParameterData.Apple.Name.HmiPasswordCode4.rawValue, partType: .HMI, bank: 2, address: 309, length: 1, type: Int.self),
    ]
    
    /// 整合型的參數陣列。(基本上用於片段讀取參數)
    public var integratedParameters: [ParameterData] {
        .init([
            .init(name: ParameterData.Apple.Name.INTEGRATED_MILEAGE_RECORD.rawValue, partType: .MainBatt, bank: 2, address: 0, length: 248, type: Any.self, dividedParameters: self.mileageRecordParameters),
            .init(name: ParameterData.Apple.Name.INTEGRATED_HMI_BANK0.rawValue, partType: .HMI, bank: 0, address: 0, length: 202, type: Any.self, dividedParameters: self.hmiBank0Parameters),
            .init(name: ParameterData.Apple.Name.INTEGRATED_HMI_ACCESS.rawValue, partType: .HMI, bank: 2, address: 306, length: 4, type: [Int].self, dividedParameters: self.himAccessControlParameters),
            .init(name: ParameterData.Apple.Name.INTEGRATED_CONTROLLER_BANK0.rawValue, partType: .Controller, bank: 0, address: 0, length: 202, type: Any.self, dividedParameters: self.controllerBank0Parameters),
            .init(name: ParameterData.Apple.Name.INTEGRATED_BATTERY_BANK0.rawValue, partType: .MainBatt, bank: 0, address: 0, length: 202, type: Any.self, dividedParameters: self.batteryBank0Parameters),
            .init(name: ParameterData.Apple.Name.INTEGRATED_ASSIST_LEVEL.rawValue, partType: .Controller, bank: 2, address: 133, length: 24, type: Any.self, dividedParameters: self.assistLevelParameters),
            .init(name: ParameterData.Apple.Name.INTEGRATED_PEDAL_ASSISTANCE.rawValue, partType: .Controller, bank: 2, address: 115, length: 104, type: [Int].self, dividedParameters: self.pedalAssistanceParameters)
        ])
    }
    
    public var parameters: [ParameterData] {
        self.normalParameters + self.assistLevelParameters + self.mileageRecordParameters + self.pedalAssistanceParameters + self.integratedParameters + self.himAccessControlParameters
    }
    
    public func asAppleRepository() throws -> AppleParameterDataRepository {
        self
    }
    
    public func asOrangeRepository() throws -> OrangeParameterDataRepository {
        throw BaseParameterDataRepository.Error.wrongType(type(of: self))
    }

    public func asCherryRepository() throws -> CherryParameterDataRepository {
        throw BaseParameterDataRepository.Error.wrongType(type(of: self))
    }
}
