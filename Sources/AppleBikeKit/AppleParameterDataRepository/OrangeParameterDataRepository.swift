//
//  OrangeParameterDataRepository.swift
//  
//
//  Created by Yves Tsai on 2024/3/27.
//

import Foundation

import CoreSDKService

public class OrangeParameterDataRepository: BaseParameterDataRepository, ParameterDataSource {
    
    lazy public private(set) var hmiBank0Parameters: [ParameterData] = [
        .init(name: ParameterData.Orange.HMI.Bank0.PRO_SMID.rawValue, partType: .HMI, bank: 0, address: 0, length: 15, type: String.self),
        .init(name: ParameterData.Orange.HMI.Bank0.PRO_DMID.rawValue, partType: .HMI, bank: 0, address: 15, length: 17, type: String.self),
        .init(name: ParameterData.Orange.HMI.Bank0.PRO_SSN.rawValue, partType: .HMI, bank: 0, address: 32, length: 32, type: String.self),
        .init(name: ParameterData.Orange.HMI.Bank0.PRO_DSN.rawValue, partType: .HMI, bank: 0, address: 64, length: 32, type: String.self),
        .init(name: ParameterData.Orange.HMI.Bank0.PRO_FRAME.rawValue, partType: .HMI, bank: 0, address: 96, length: 32, type: String.self),
        .init(name: ParameterData.Orange.HMI.Bank0.PRO_SALE_DATE.rawValue, partType: .HMI, bank: 0, address: 128, length: 6, type: String.self),
        .init(name: ParameterData.Orange.HMI.Bank0.PRO_FW_APP_VER.rawValue, partType: .HMI, bank: 0, address: 134, length: 6, type: String.self),
        .init(name: ParameterData.Orange.HMI.Bank0.PRO_FW_BTL_VER.rawValue, partType: .HMI, bank: 0, address: 140, length: 6, type: String.self),
        .init(name: ParameterData.Orange.HMI.Bank0.PRO_FW_SDK_VER.rawValue, partType: .HMI, bank: 0, address: 146, length: 6, type: String.self),
        .init(name: ParameterData.Orange.HMI.Bank0.PRO_HW_VER.rawValue, partType: .HMI, bank: 0, address: 152, length: 11, type: String.self),
        .init(name: ParameterData.Orange.HMI.Bank0.PRO_PARA_VER.rawValue, partType: .HMI, bank: 0, address: 163, length: 6, type: String.self),
        .init(name: ParameterData.Orange.HMI.Bank0.PRO_PROTOCOL_VER.rawValue, partType: .HMI, bank: 0, address: 169, length: 11, type: String.self),
        .init(name: ParameterData.Orange.HMI.Bank0.PRO_BT_DEV_NAME.rawValue, partType: .HMI, bank: 0, address: 180, length: 22, type: String.self),
        .init(name: ParameterData.Orange.HMI.Bank0.PRO_MANUFACTURE_DATE.rawValue, partType: .HMI, bank: 0, address: 202, length: 6, type: String.self),
        .init(name: ParameterData.Orange.HMI.Bank0.PRO_CORE_SDK_VER.rawValue, partType: .HMI, bank: 0, address: 208, length: 9, type: String.self),
        .init(name: ParameterData.Orange.HMI.Bank0.PRO_CUST_PART_NUM.rawValue, partType: .HMI, bank: 0, address: 525, length: 64, type: String.self),
        .init(name: ParameterData.Orange.HMI.Bank0.PRO_CUST_PART_NAME.rawValue, partType: .HMI, bank: 0, address: 589, length: 128, type: String.self),
        .init(name: ParameterData.Orange.HMI.Bank0.PRO_CUST_PROJ_CODE.rawValue, partType: .HMI, bank: 0, address: 717, length: 64, type: String.self),
        .init(name: ParameterData.Orange.HMI.Bank0.PRO_END_CUST.rawValue, partType: .HMI, bank: 0, address: 781, length: 32, type: String.self),
        .init(name: ParameterData.Orange.HMI.Bank0.PRO_SUPPLIER.rawValue, partType: .HMI, bank: 0, address: 813, length: 32, type: String.self),
        .init(name: ParameterData.Orange.HMI.Bank0.PRO_CUST_HW_VER.rawValue, partType: .HMI, bank: 0, address: 845, length: 16, type: String.self),
        .init(name: ParameterData.Orange.HMI.Bank0.PRO_PROG_SEC.rawValue, partType: .HMI, bank: 0, address: 1023, length: 1, type: String.self),
    ]
    
    lazy public private(set) var hmiBank1Parameters: [ParameterData] = [
        .init(name: ParameterData.Orange.HMI.Bank1.REC_MAINT_DIST.rawValue, partType: .HMI, bank: 1, address: 271, length: 4, type: Int.self),
        .init(name: ParameterData.Orange.HMI.Bank1.METER_SLEEP_TIME.rawValue, partType: .HMI, bank: 1, address: 339, length: 2, type: Int.self),
        .init(name: ParameterData.Orange.HMI.Bank1.METER_MAINT_DIST.rawValue, partType: .HMI, bank: 1, address: 344, length: 4, type: Int.self),
        .init(name: ParameterData.Orange.HMI.Bank1.METER_BRIGHT_AUTO_EN.rawValue, partType: .HMI, bank: 1, address: 348, length: 1, type: Int.self),
        .init(name: ParameterData.Orange.HMI.Bank1.METER_BRIGHT_NOW.rawValue, partType: .HMI, bank: 1, address: 349, length: 1, type: Int.self)
    ]
    
    lazy public private(set) var hmiBank2Parameters: [ParameterData] = [
        .init(name: ParameterData.Orange.HMI.Bank2.TRIP_TOT_DIST.rawValue, partType: .HMI, bank: 2, address: 0, length: 4, type: Int.self),
        .init(name: ParameterData.Orange.HMI.Bank2.TRIP_TOT_TIME.rawValue, partType: .HMI, bank: 2, address: 4, length: 4, type: Int.self),
        .init(name: ParameterData.Orange.HMI.Bank2.TRIP_AVG_SPD.rawValue, partType: .HMI, bank: 2, address: 8, length: 2, type: Int.self),
        .init(name: ParameterData.Orange.HMI.Bank2.TRIP_MAX_SPD.rawValue, partType: .HMI, bank: 2, address: 10, length: 2, type: Int.self),
        .init(name: ParameterData.Orange.HMI.Bank2.TRIP_AVG_CUR.rawValue, partType: .HMI, bank: 2, address: 12, length: 2, type: Int.self),
        .init(name: ParameterData.Orange.HMI.Bank2.TRIP_MAX_CUR.rawValue, partType: .HMI, bank: 2, address: 14, length: 2, type: Int.self),
        .init(name: ParameterData.Orange.HMI.Bank2.TRIP_AVG_CAD_SPD.rawValue, partType: .HMI, bank: 2, address: 16, length: 1, type: Int.self),
        .init(name: ParameterData.Orange.HMI.Bank2.TRIP_MAX_CAD_SPD.rawValue, partType: .HMI, bank: 2, address: 17, length: 1, type: Int.self),
        .init(name: ParameterData.Orange.HMI.Bank2.TRIP_AVG_TORQ.rawValue, partType: .HMI, bank: 2, address: 18, length: 2, type: Int.self),
        .init(name: ParameterData.Orange.HMI.Bank2.TRIP_MAX_TORQ.rawValue, partType: .HMI, bank: 2, address: 20, length: 2, type: Int.self),
        .init(name: ParameterData.Orange.HMI.Bank2.TRIP_AVG_PEDAL_WATT.rawValue, partType: .HMI, bank: 2, address: 22, length: 2, type: Int.self),
        .init(name: ParameterData.Orange.HMI.Bank2.TRIP_MAX_PEDAL_WATT.rawValue, partType: .HMI, bank: 2, address: 24, length: 2, type: Int.self),
        .init(name: ParameterData.Orange.HMI.Bank2.TRIP_AVG_MOTOR_WATT.rawValue, partType: .HMI, bank: 2, address: 26, length: 2, type: Int.self),
        .init(name: ParameterData.Orange.HMI.Bank2.TRIP_MAX_MOTOR_WATT.rawValue, partType: .HMI, bank: 2, address: 28, length: 2, type: Int.self),
        .init(name: ParameterData.Orange.HMI.Bank2.TRIP_CER.rawValue, partType: .HMI, bank: 2, address: 30, length: 2, type: Int.self),
        .init(name: ParameterData.Orange.HMI.Bank2.TRIP_CALORIE.rawValue, partType: .HMI, bank: 2, address: 32, length: 2, type: Int.self),
        .init(name: ParameterData.Orange.HMI.Bank2.TRIP_LEVEL0_TIME.rawValue, partType: .HMI, bank: 2, address: 34, length: 4, type: Int.self),
        .init(name: ParameterData.Orange.HMI.Bank2.TRIP_LEVEL1_TIME.rawValue, partType: .HMI, bank: 2, address: 38, length: 4, type: Int.self),
        .init(name: ParameterData.Orange.HMI.Bank2.TRIP_LEVEL2_TIME.rawValue, partType: .HMI, bank: 2, address: 42, length: 4, type: Int.self),
        .init(name: ParameterData.Orange.HMI.Bank2.TRIP_LEVEL3_TIME.rawValue, partType: .HMI, bank: 2, address: 46, length: 4, type: Int.self),
        .init(name: ParameterData.Orange.HMI.Bank2.TRIP_LEVEL4_TIME.rawValue, partType: .HMI, bank: 2, address: 50, length: 4, type: Int.self),
        .init(name: ParameterData.Orange.HMI.Bank2.TRIP_LEVEL5_TIME.rawValue, partType: .HMI, bank: 2, address: 54, length: 4, type: Int.self),
        .init(name: ParameterData.Orange.HMI.Bank2.TRIP_LEVEL6_TIME.rawValue, partType: .HMI, bank: 2, address: 58, length: 4, type: Int.self),
        .init(name: ParameterData.Orange.HMI.Bank2.TRIP_LEVEL7_TIME.rawValue, partType: .HMI, bank: 2, address: 62, length: 4, type: Int.self),
        .init(name: ParameterData.Orange.HMI.Bank2.TRIP_LEVEL8_TIME.rawValue, partType: .HMI, bank: 2, address: 66, length: 4, type: Int.self),
        .init(name: ParameterData.Orange.HMI.Bank2.TRIP_LEVEL9_TIME.rawValue, partType: .HMI, bank: 2, address: 70, length: 4, type: Int.self),
        .init(name: ParameterData.Orange.HMI.Bank2.DISP_MAINT_MARK_SW.rawValue, partType: .HMI, bank: 2, address: 150, length: 1, type: Int.self),
        .init(name: ParameterData.Orange.HMI.Bank2.DISP_RANGE_SW.rawValue, partType: .HMI, bank: 2, address: 151, length: 1, type: Int.self),
        .init(name: ParameterData.Orange.HMI.Bank2.DISP_UNIT_SW.rawValue, partType: .HMI, bank: 2, address: 152, length: 1, type: Int.self),
    ]
    
    lazy public private(set) var controllerBank0Parameters: [ParameterData] = [
        .init(name: ParameterData.Orange.Controller.Bank0.PRO_SMID.rawValue, partType: .Controller, bank: 0, address: 0, length: 15, type: String.self),
        .init(name: ParameterData.Orange.Controller.Bank0.PRO_DMID.rawValue, partType: .Controller, bank: 0, address: 15, length: 17, type: String.self),
        .init(name: ParameterData.Orange.Controller.Bank0.PRO_SSN.rawValue, partType: .Controller, bank: 0, address: 32, length: 32, type: String.self),
        .init(name: ParameterData.Orange.Controller.Bank0.PRO_DSN.rawValue, partType: .Controller, bank: 0, address: 64, length: 32, type: String.self),
        .init(name: ParameterData.Orange.Controller.Bank0.PRO_FRAME.rawValue, partType: .Controller, bank: 0, address: 96, length: 32, type: String.self),
        .init(name: ParameterData.Orange.Controller.Bank0.PRO_SALE_DATE.rawValue, partType: .Controller, bank: 0, address: 128, length: 6, type: String.self),
        .init(name: ParameterData.Orange.Controller.Bank0.PRO_FW_APP_VER.rawValue, partType: .Controller, bank: 0, address: 134, length: 6, type: String.self),
        .init(name: ParameterData.Orange.Controller.Bank0.PRO_FW_BTL_VER.rawValue, partType: .Controller, bank: 0, address: 140, length: 6, type: String.self),
        .init(name: ParameterData.Orange.Controller.Bank0.PRO_FW_SDK_VER.rawValue, partType: .Controller, bank: 0, address: 146, length: 6, type: String.self),
        .init(name: ParameterData.Orange.Controller.Bank0.PRO_HW_VER.rawValue, partType: .Controller, bank: 0, address: 152, length: 11, type: String.self),
        .init(name: ParameterData.Orange.Controller.Bank0.PRO_PARA_VER.rawValue, partType: .Controller, bank: 0, address: 163, length: 6, type: String.self),
        .init(name: ParameterData.Orange.Controller.Bank0.PRO_PROTOCOL_VER.rawValue, partType: .Controller, bank: 0, address: 169, length: 11, type: String.self),
        .init(name: ParameterData.Orange.Controller.Bank0.PRO_BT_DEV_NAME.rawValue, partType: .Controller, bank: 0, address: 180, length: 22, type: String.self),
        .init(name: ParameterData.Orange.Controller.Bank0.PRO_MANUFACTURE_DATE.rawValue, partType: .Controller, bank: 0, address: 202, length: 6, type: String.self),
        .init(name: ParameterData.Orange.Controller.Bank0.PRO_CORE_SDK_VER.rawValue, partType: .Controller, bank: 0, address: 208, length: 9, type: String.self),
        .init(name: ParameterData.Orange.Controller.Bank0.PRO_CUST_PART_NUM.rawValue, partType: .Controller, bank: 0, address: 525, length: 64, type: String.self),
        .init(name: ParameterData.Orange.Controller.Bank0.PRO_CUST_PART_NAME.rawValue, partType: .Controller, bank: 0, address: 589, length: 128, type: String.self),
        .init(name: ParameterData.Orange.Controller.Bank0.PRO_CUST_PROJ_CODE.rawValue, partType: .Controller, bank: 0, address: 717, length: 64, type: String.self),
        .init(name: ParameterData.Orange.Controller.Bank0.PRO_END_CUST.rawValue, partType: .Controller, bank: 0, address: 781, length: 32, type: String.self),
        .init(name: ParameterData.Orange.Controller.Bank0.PRO_SUPPLIER.rawValue, partType: .Controller, bank: 0, address: 813, length: 32, type: String.self),
        .init(name: ParameterData.Orange.Controller.Bank0.PRO_CUST_HW_VER.rawValue, partType: .Controller, bank: 0, address: 845, length: 16, type: String.self),
        .init(name: ParameterData.Orange.Controller.Bank0.PRO_PROG_SEC.rawValue, partType: .Controller, bank: 0, address: 1023, length: 1, type: String.self),
    ]
    
    lazy public private(set) var controllerBank1Lv1AssistParameters: [ParameterData] = [
        .init(name: ParameterData.Orange.Controller.Bank1.LV1_ASSIST_RADIO.rawValue, partType: .Controller, bank: 1, address: 21, length: 1, type: Int.self),
        .init(name: ParameterData.Orange.Controller.Bank1.LV1_ASSIST_MAX_SPD.rawValue, partType: .Controller, bank: 1, address: 22, length: 1, type: Int.self),
        .init(name: ParameterData.Orange.Controller.Bank1.LV1_ASSIST_STA_LV.rawValue, partType: .Controller, bank: 1, address: 23, length: 1, type: Int.self),
    ]
    
    lazy public private(set) var controllerBank1Lv2AssistParameters: [ParameterData] = [
        .init(name: ParameterData.Orange.Controller.Bank1.LV2_ASSIST_RADIO.rawValue, partType: .Controller, bank: 1, address: 53, length: 1, type: Int.self),
        .init(name: ParameterData.Orange.Controller.Bank1.LV2_ASSIST_MAX_SPD.rawValue, partType: .Controller, bank: 1, address: 54, length: 1, type: Int.self),
        .init(name: ParameterData.Orange.Controller.Bank1.LV2_ASSIST_STA_LV.rawValue, partType: .Controller, bank: 1, address: 55, length: 1, type: Int.self),
    ]
    
    lazy public private(set) var controllerBank1Lv3AssistParameters: [ParameterData] = [
        .init(name: ParameterData.Orange.Controller.Bank1.LV3_ASSIST_RADIO.rawValue, partType: .Controller, bank: 1, address: 85, length: 1, type: Int.self),
        .init(name: ParameterData.Orange.Controller.Bank1.LV3_ASSIST_MAX_SPD.rawValue, partType: .Controller, bank: 1, address: 86, length: 1, type: Int.self),
        .init(name: ParameterData.Orange.Controller.Bank1.LV3_ASSIST_STA_LV.rawValue, partType: .Controller, bank: 1, address: 87, length: 1, type: Int.self),
    ]
    
    lazy public private(set) var controllerBank1Lv4AssistParameters: [ParameterData] = [
        .init(name: ParameterData.Orange.Controller.Bank1.LV4_ASSIST_RADIO.rawValue, partType: .Controller, bank: 1, address: 117, length: 1, type: Int.self),
        .init(name: ParameterData.Orange.Controller.Bank1.LV4_ASSIST_MAX_SPD.rawValue, partType: .Controller, bank: 1, address: 118, length: 1, type: Int.self),
        .init(name: ParameterData.Orange.Controller.Bank1.LV4_ASSIST_STA_LV.rawValue, partType: .Controller, bank: 1, address: 119, length: 1, type: Int.self),
    ]
    
    lazy public private(set) var controllerBank1Lv5AssistParameters: [ParameterData] = [
        .init(name: ParameterData.Orange.Controller.Bank1.LV5_ASSIST_RADIO.rawValue, partType: .Controller, bank: 1, address: 149, length: 1, type: Int.self),
        .init(name: ParameterData.Orange.Controller.Bank1.LV5_ASSIST_MAX_SPD.rawValue, partType: .Controller, bank: 1, address: 150, length: 1, type: Int.self),
        .init(name: ParameterData.Orange.Controller.Bank1.LV5_ASSIST_STA_LV.rawValue, partType: .Controller, bank: 1, address: 151, length: 1, type: Int.self),
    ]
    
    lazy public private(set) var controllerBank1Lv6AssistParameters: [ParameterData] = [
        .init(name: ParameterData.Orange.Controller.Bank1.LV6_ASSIST_RADIO.rawValue, partType: .Controller, bank: 1, address: 181, length: 1, type: Int.self),
        .init(name: ParameterData.Orange.Controller.Bank1.LV6_ASSIST_MAX_SPD.rawValue, partType: .Controller, bank: 1, address: 182, length: 1, type: Int.self),
        .init(name: ParameterData.Orange.Controller.Bank1.LV6_ASSIST_STA_LV.rawValue, partType: .Controller, bank: 1, address: 183, length: 1, type: Int.self),
    ]
    
    lazy public private(set) var controllerBank1Lv7AssistParameters: [ParameterData] = [
        .init(name: ParameterData.Orange.Controller.Bank1.LV7_ASSIST_RADIO.rawValue, partType: .Controller, bank: 1, address: 213, length: 1, type: Int.self),
        .init(name: ParameterData.Orange.Controller.Bank1.LV7_ASSIST_MAX_SPD.rawValue, partType: .Controller, bank: 1, address: 214, length: 1, type: Int.self),
        .init(name: ParameterData.Orange.Controller.Bank1.LV7_ASSIST_STA_LV.rawValue, partType: .Controller, bank: 1, address: 215, length: 1, type: Int.self),
    ]
    
    lazy public private(set) var controllerBank1Lv8AssistParameters: [ParameterData] = [
        .init(name: ParameterData.Orange.Controller.Bank1.LV8_ASSIST_RADIO.rawValue, partType: .Controller, bank: 1, address: 245, length: 1, type: Int.self),
        .init(name: ParameterData.Orange.Controller.Bank1.LV8_ASSIST_MAX_SPD.rawValue, partType: .Controller, bank: 1, address: 246, length: 1, type: Int.self),
        .init(name: ParameterData.Orange.Controller.Bank1.LV8_ASSIST_STA_LV.rawValue, partType: .Controller, bank: 1, address: 247, length: 1, type: Int.self),
    ]
    
    lazy public private(set) var controllerBank1Lv9AssistParameters: [ParameterData] = [
        .init(name: ParameterData.Orange.Controller.Bank1.LV9_ASSIST_RADIO.rawValue, partType: .Controller, bank: 1, address: 277, length: 1, type: Int.self),
        .init(name: ParameterData.Orange.Controller.Bank1.LV9_ASSIST_MAX_SPD.rawValue, partType: .Controller, bank: 1, address: 278, length: 1, type: Int.self),
        .init(name: ParameterData.Orange.Controller.Bank1.LV9_ASSIST_STA_LV.rawValue, partType: .Controller, bank: 1, address: 279, length: 1, type: Int.self),
    ]
    
    lazy public private(set) var controllerBank1Parameters: [ParameterData] = {
        [
            .init(name: ParameterData.Orange.Controller.Bank1.MAX_ASSIST_LV.rawValue, partType: .Controller, bank: 1, address: 0, length: 1, type: Int.self),
            .init(name: ParameterData.Orange.Controller.Bank1.SPD_MAX_LIMIT.rawValue, partType: .Controller, bank: 1, address: 3, length: 2, type: Int.self),
        ] 
        + controllerBank1Lv1AssistParameters
        + controllerBank1Lv2AssistParameters
        + controllerBank1Lv3AssistParameters
        + controllerBank1Lv4AssistParameters
        + controllerBank1Lv5AssistParameters
        + controllerBank1Lv6AssistParameters
        + controllerBank1Lv7AssistParameters
        + controllerBank1Lv8AssistParameters
        + controllerBank1Lv9AssistParameters
    }()
    
    lazy public private(set) var controllerBank2Parameters: [ParameterData] = []
    
    lazy public private(set) var controllerBank3Parameters: [ParameterData] = [
        .init(name: ParameterData.Orange.Controller.Bank3.TOTAL_ODO.rawValue, partType: .Controller, bank: 3, address: 0, length: 4, type: Int.self),
        .init(name: ParameterData.Orange.Controller.Bank3.BACKUP_TOTAL_ODO.rawValue, partType: .Controller, bank: 3, address: 4, length: 4, type: Int.self),
        .init(name: ParameterData.Orange.Controller.Bank3.TOTAL_TIME.rawValue, partType: .Controller, bank: 3, address: 8, length: 4, type: Int.self),
        .init(name: ParameterData.Orange.Controller.Bank3.PRO_CHG_DSN.rawValue, partType: .Controller, bank: 3, address: 186, length: 32, type: String.self),
        .init(name: ParameterData.Orange.Controller.Bank3.PRO_MOTOR_DSN.rawValue, partType: .Controller, bank: 3, address: 268, length: 32, type: String.self),
        .init(name: ParameterData.Orange.Controller.Bank3.PRO_TORQUE_DSN.rawValue, partType: .Controller, bank: 3, address: 350, length: 32, type: String.self),
        .init(name: ParameterData.Orange.Controller.Bank3.PRO_FLIGHT_DSN.rawValue, partType: .Controller, bank: 3, address: 432, length: 32, type: String.self),
        .init(name: ParameterData.Orange.Controller.Bank3.PRO_RLIGHT_DSN.rawValue, partType: .Controller, bank: 3, address: 514, length: 32, type: String.self),
        .init(name: ParameterData.Orange.Controller.Bank3.PRO_THROTTLE_DSN.rawValue, partType: .Controller, bank: 3, address: 596, length: 32, type: String.self),
    ]
    
    lazy public private(set) var batteryBank0Parameters: [ParameterData] = [
        .init(name: ParameterData.Orange.BMS1.Bank0.PRO_SMID.rawValue, partType: .MainBatt, bank: 0, address: 0, length: 15, type: String.self),
        .init(name: ParameterData.Orange.BMS1.Bank0.PRO_DMID.rawValue, partType: .MainBatt, bank: 0, address: 15, length: 17, type: String.self),
        .init(name: ParameterData.Orange.BMS1.Bank0.PRO_SSN.rawValue, partType: .MainBatt, bank: 0, address: 32, length: 32, type: String.self),
        .init(name: ParameterData.Orange.BMS1.Bank0.PRO_DSN.rawValue, partType: .MainBatt, bank: 0, address: 64, length: 32, type: String.self),
        .init(name: ParameterData.Orange.BMS1.Bank0.PRO_FRAME.rawValue, partType: .MainBatt, bank: 0, address: 96, length: 32, type: String.self),
        .init(name: ParameterData.Orange.BMS1.Bank0.PRO_SALE_DATE.rawValue, partType: .MainBatt, bank: 0, address: 128, length: 6, type: String.self),
        .init(name: ParameterData.Orange.BMS1.Bank0.PRO_FW_APP_VER.rawValue, partType: .MainBatt, bank: 0, address: 134, length: 6, type: String.self),
        .init(name: ParameterData.Orange.BMS1.Bank0.PRO_FW_BTL_VER.rawValue, partType: .MainBatt, bank: 0, address: 140, length: 6, type: String.self),
        .init(name: ParameterData.Orange.BMS1.Bank0.PRO_FW_SDK_VER.rawValue, partType: .MainBatt, bank: 0, address: 146, length: 6, type: String.self),
        .init(name: ParameterData.Orange.BMS1.Bank0.PRO_HW_VER.rawValue, partType: .MainBatt, bank: 0, address: 152, length: 11, type: String.self),
        .init(name: ParameterData.Orange.BMS1.Bank0.PRO_PARA_VER.rawValue, partType: .MainBatt, bank: 0, address: 163, length: 6, type: String.self),
        .init(name: ParameterData.Orange.BMS1.Bank0.PRO_PROTOCOL_VER.rawValue, partType: .MainBatt, bank: 0, address: 169, length: 11, type: String.self),
        .init(name: ParameterData.Orange.BMS1.Bank0.PRO_BT_DEV_NAME.rawValue, partType: .MainBatt, bank: 0, address: 180, length: 22, type: String.self),
        .init(name: ParameterData.Orange.BMS1.Bank0.PRO_MANUFACTURE_DATE.rawValue, partType: .MainBatt, bank: 0, address: 202, length: 6, type: String.self),
        .init(name: ParameterData.Orange.BMS1.Bank0.PRO_CORE_SDK_VER.rawValue, partType: .MainBatt, bank: 0, address: 208, length: 9, type: String.self),
        .init(name: ParameterData.Orange.BMS1.Bank0.PRO_CUST_PART_NUM.rawValue, partType: .MainBatt, bank: 0, address: 525, length: 64, type: String.self),
        .init(name: ParameterData.Orange.BMS1.Bank0.PRO_CUST_PART_NAME.rawValue, partType: .MainBatt, bank: 0, address: 589, length: 128, type: String.self),
        .init(name: ParameterData.Orange.BMS1.Bank0.PRO_CUST_PROJ_CODE.rawValue, partType: .MainBatt, bank: 0, address: 717, length: 64, type: String.self),
        .init(name: ParameterData.Orange.BMS1.Bank0.PRO_END_CUST.rawValue, partType: .MainBatt, bank: 0, address: 781, length: 32, type: String.self),
        .init(name: ParameterData.Orange.BMS1.Bank0.PRO_SUPPLIER.rawValue, partType: .MainBatt, bank: 0, address: 813, length: 32, type: String.self),
        .init(name: ParameterData.Orange.BMS1.Bank0.PRO_CUST_HW_VER.rawValue, partType: .MainBatt, bank: 0, address: 845, length: 16, type: String.self),
        .init(name: ParameterData.Orange.BMS1.Bank0.PRO_PROG_SEC.rawValue, partType: .MainBatt, bank: 0, address: 1023, length: 1, type: String.self),
    ]
    
    public private(set) lazy var normalParameters: [ParameterData] = {
        self.hmiBank0Parameters +
        self.hmiBank1Parameters +
        self.hmiBank2Parameters +
        self.controllerBank0Parameters +
        self.controllerBank1Parameters +
        self.controllerBank2Parameters +
        self.controllerBank3Parameters +
        self.batteryBank0Parameters
    }()
    
    public var integratedParameters: [ParameterData] {
        [
            .init(name: ParameterData.Orange.Integrated.HMI_BANK0.rawValue, partType: .HMI, bank: 0, address: 0, length: 1024, type: [Int].self, dividedParameters: self.hmiBank0Parameters),
            .init(name: ParameterData.Orange.Integrated.HMI_BANK2.rawValue, partType: .HMI, bank: 2, address: 0, length: 153, type: [Int].self, dividedParameters: self.hmiBank2Parameters),
            .init(name: ParameterData.Orange.Integrated.CONTROLLER_BANK0.rawValue, partType: .Controller, bank: 0, address: 0, length: 1024, type: [Int].self, dividedParameters: self.controllerBank0Parameters),
            .init(name: ParameterData.Orange.Integrated.CONTROLLER_BANK1.rawValue, partType: .Controller, bank: 1, address: 0, length: 279+1, type: [Int].self, dividedParameters: self.controllerBank1Parameters),
            .init(name: ParameterData.Orange.Integrated.CONTROLLER_BANK1_LV1_ASSIST.rawValue, partType: .Controller, bank: 1, address: 21, length: 3, type: [Int].self, dividedParameters: self.controllerBank1Lv1AssistParameters),
            .init(name: ParameterData.Orange.Integrated.CONTROLLER_BANK1_LV2_ASSIST.rawValue, partType: .Controller, bank: 1, address: 53, length: 3, type: [Int].self, dividedParameters: self.controllerBank1Lv2AssistParameters),
            .init(name: ParameterData.Orange.Integrated.CONTROLLER_BANK1_LV3_ASSIST.rawValue, partType: .Controller, bank: 1, address: 85, length: 3, type: [Int].self, dividedParameters: self.controllerBank1Lv3AssistParameters),
            .init(name: ParameterData.Orange.Integrated.CONTROLLER_BANK1_LV4_ASSIST.rawValue, partType: .Controller, bank: 1, address: 117, length: 3, type: [Int].self, dividedParameters: self.controllerBank1Lv4AssistParameters),
            .init(name: ParameterData.Orange.Integrated.CONTROLLER_BANK1_LV5_ASSIST.rawValue, partType: .Controller, bank: 1, address: 149, length: 3, type: [Int].self, dividedParameters: self.controllerBank1Lv5AssistParameters),
            .init(name: ParameterData.Orange.Integrated.CONTROLLER_BANK1_LV6_ASSIST.rawValue, partType: .Controller, bank: 1, address: 181, length: 3, type: [Int].self, dividedParameters: self.controllerBank1Lv6AssistParameters),
            .init(name: ParameterData.Orange.Integrated.CONTROLLER_BANK1_LV7_ASSIST.rawValue, partType: .Controller, bank: 1, address: 213, length: 3, type: [Int].self, dividedParameters: self.controllerBank1Lv7AssistParameters),
            .init(name: ParameterData.Orange.Integrated.CONTROLLER_BANK1_LV8_ASSIST.rawValue, partType: .Controller, bank: 1, address: 245, length: 3, type: [Int].self, dividedParameters: self.controllerBank1Lv8AssistParameters),
            .init(name: ParameterData.Orange.Integrated.CONTROLLER_BANK1_LV9_ASSIST.rawValue, partType: .Controller, bank: 1, address: 277, length: 3, type: [Int].self, dividedParameters: self.controllerBank1Lv9AssistParameters),
            .init(name: ParameterData.Orange.Integrated.CONTROLLER_BANK3.rawValue, partType: .Controller, bank: 3, address: 0, length: 596+32, type: [Int].self, dividedParameters: self.controllerBank3Parameters),
            .init(name: ParameterData.Orange.Integrated.BATTERY_BANK0.rawValue, partType: .MainBatt, bank: 0, address: 0, length: 1024, type: [Int].self, dividedParameters: self.batteryBank0Parameters),
        ]
    }
    
    public var parameters: [ParameterData] {
        self.normalParameters + self.integratedParameters
    }
    
    public func asAppleRepository() throws -> AppleParameterDataRepository {
        throw BaseParameterDataRepository.Error.wrongType(type(of: self))
    }
    
    public func asOrangeRepository() throws -> OrangeParameterDataRepository {
        self
    }
    
    public func asCherryRepository() throws -> CherryParameterDataRepository {
        throw BaseParameterDataRepository.Error.wrongType(type(of: self))
    }
}
