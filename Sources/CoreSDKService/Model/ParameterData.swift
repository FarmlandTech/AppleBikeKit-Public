//
//  ParameterData.swift
//  
//
//  Created by Yves Tsai on 2023/4/20.
//

import Foundation
import Combine

public class ParameterData {
    public private(set) var name: String
    public private(set) var partType: CommunicationPartType
    public private(set) var bank: UInt8
    public private(set) var address: UInt16
    public private(set) var length: UInt16
    public private(set) var type: Any
    // 目前 var value: Any? 與 var subject: CurrentValueSubject<Any?, Never> 的存在，有相當程度的重複性
    // ，但因為早期規劃，暫時先保留，後面的版本在優化參數架構。
    public var value: Any?
    public private(set) var subject: CurrentValueSubject<Any?, Never> = .init(nil)
    
    public private(set) var dividedParameters: [ParameterData]?
    
    public init(name: String, partType: CommunicationPartType, bank: UInt8, address: UInt16, length: UInt16, type: Any, value: Any? = nil, dividedParameters: [ParameterData]? = nil) {
        self.name = name
        self.partType = partType
        self.bank = bank
        self.address = address
        self.length = length
        self.type = type
        self.value = value
        self.dividedParameters = dividedParameters
    }
}

extension ParameterData {
    public struct Apple {
        public enum Name: String {
            case INTEGRATED_HMI_BANK0
            case INTEGRATED_HMI_BANK1
            case INTEGRATED_HMI_BANK2
            case INTEGRATED_MILEAGE_RECORD
            case INTEGRATED_HMI_ACCESS  // 螢幕鎖相關參數。
            case INTEGRATED_CONTROLLER_BANK0
            case INTEGRATED_ASSISTANCE_CONFIGURATION
            case INTEGRATED_WALK_ASSISTANCE
            case INTEGRATED_LV1_AST_RATIO_AND_SPD
            case INTEGRATED_LV2_AST_RATIO_AND_SPD
            case INTEGRATED_LV3_AST_RATIO_AND_SPD
            case INTEGRATED_LV4_AST_RATIO_AND_SPD
            case INTEGRATED_LV5_AST_RATIO_AND_SPD
            case INTEGRATED_PEDAL_ASSISTANCE
            case INTEGRATED_BATTERY_BANK0
            
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
            case HmiSvrToken
            case REC_MAINT_DIST  // 上次保養里程。
            case METER_SLEEP_TIME  // 自動休眠時間，Max: 10800 Sec = 3小時。
            case METER_MAINT_DIST  // 保養間隔里程。
            case DISP_MAINT_MARK_SW  // 保養標誌顯示設定。
            case DISP_UNIT_SW  // 單位選擇。
            case DISP_BRIGHTNESS // 背光亮度設定。
            case HmiPasswordCode1  // 解鎖密碼。
            case HmiPasswordCode2  // 解鎖密碼。
            case HmiPasswordCode3  // 解鎖密碼。
            case HmiPasswordCode4  // 解鎖密碼。
            case HmiErrorLimit  // 密碼錯誤次數上限。
            case HmiErrorCount  // 密碼錯誤累積次數。
            
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
            
            case Controller_SUP_ASSIST
            case Controller_PEDAL_AST_MODE
            case Controller_SUP_MAX_AST_SPD
            case Controller_THROTTLE_AST_EN_MODE
            case Controller_THROTTLE_AST_MODE
            case Controller_W_AST_SPD
            case Controller_W_AST_MAX_CUR
            case Controller_W_AST_CTRL_FREQ
            case Controller_W_AST_ACC_DEC
            case Controller_W_AST_OCP_DEC
            case Controller_W_AST_STOP_DEC

            case Controller_P_STR_MAX_DEG
            case Controller_P_STR_MIN_DEG
            case Controller_P_STR_MAX_TORQ
            case Controller_P_STR_MIN_TORQ
            case Controller_P_STR_STR_SPD
            case Controller_P_STR_END_SPD
            case Controller_P_STOP_MAX_CAD_SPD
            case Controller_P_STOP_MIN_CAD_SPD
            case Controller_P_STOP_STR_SPD
            case Controller_P_STOP_END_SPD
            case Controller_P_AST_LV1_STR_RANG
            case Controller_P_LV1_MAX_AST_RATIO
            case Controller_P_LV1_MIN_AST_RATIO
            case Controller_P_LV1_AST_RATIO_STR_SPD
            case Controller_P_LV1_AST_RATIO_END_SPD
            case Controller_P_LV2_MAX_AST_RATIO
            case Controller_P_LV2_MIN_AST_RATIO
            case Controller_P_LV2_AST_RATIO_STR_SPD
            case Controller_P_LV2_AST_RATIO_END_SPD
            case Controller_P_LV3_MAX_AST_RATIO
            case Controller_P_LV3_MIN_AST_RATIO
            case Controller_P_LV3_AST_RATIO_STR_SPD
            case Controller_P_LV3_AST_RATIO_END_SPD
            case Controller_P_LV4_MAX_AST_RATIO
            case Controller_P_LV4_MIN_AST_RATIO
            case Controller_P_LV4_AST_RATIO_STR_SPD
            case Controller_P_LV4_AST_RATIO_END_SPD
            case Controller_P_LV5_MAX_AST_RATIO
            case Controller_P_LV5_MIN_AST_RATIO
            case Controller_P_LV5_AST_RATIO_STR_SPD
            case Controller_P_LV5_AST_RATIO_END_SPD
            case Controller_P_AST_CTRL_FREQ
            case Controller_P_AST_LV1_STR_ACC
            case Controller_P_AST_LV1_STR_DEC
            case Controller_P_AST_LV1_MAX_CUR
            case Controller_P_AST_LV1_ACC
            case Controller_P_AST_LV1_DEC
            case Controller_P_AST_LV2_MAX_CUR
            case Controller_P_AST_LV2_ACC
            case Controller_P_AST_LV2_DEC
            case Controller_P_AST_LV3_MAX_CUR
            case Controller_P_AST_LV3_ACC
            case Controller_P_AST_LV3_DEC
            case Controller_P_AST_LV4_MAX_CUR
            case Controller_P_AST_LV4_ACC
            case Controller_P_AST_LV4_DEC
            case Controller_P_AST_LV5_MAX_CUR
            case Controller_P_AST_LV5_ACC
            case Controller_P_AST_LV5_DEC
            case Controller_P_AST_OSP_DEC
            case Controller_P_AST_OCP_DEC
            case Controller_P_AST_STOP_DEC
            case Controller_P_AST_LV2_STR_RANG
            case Controller_P_AST_LV3_STR_RANG
            case Controller_P_AST_LV4_STR_RANG
            case Controller_P_AST_LV5_STR_RANG
            case Controller_P_AST_LV2_STR_ACC
            case Controller_P_AST_LV2_STR_DEC
            case Controller_P_AST_LV3_STR_ACC
            case Controller_P_AST_LV3_STR_DEC
            case Controller_P_AST_LV4_STR_ACC
            case Controller_P_AST_LV4_STR_DEC
            case Controller_P_AST_LV5_STR_ACC
            case Controller_P_AST_LV5_STR_DEC
            case Controller_P_AST_BRAKE_DEC
            case Controller_P_AST_LIM_CUR_DEC
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
    }
}

extension ParameterData {
    public struct Orange {
        public struct HMI {
            public enum Bank0: String {
                case PRO_SMID
                case PRO_DMID
                case PRO_SSN
                case PRO_DSN
                case PRO_FRAME
                case PRO_SALE_DATE
                case PRO_FW_APP_VER
                case PRO_FW_BTL_VER
                case PRO_FW_SDK_VER
                case PRO_HW_VER
                case PRO_PARA_VER
                case PRO_PROTOCOL_VER
                case PRO_BT_DEV_NAME
                case PRO_MANUFACTURE_DATE
                case PRO_CORE_SDK_VER
                case PRO_CUST_PART_NUM
                case PRO_CUST_PART_NAME
                case PRO_CUST_PROJ_CODE
                case PRO_END_CUST
                case PRO_SUPPLIER
                case PRO_CUST_HW_VER
                case PRO_PROG_SEC
            }
            
            public enum Bank1: String {
                case RIDE_LV0_TOT_DIST
                case RIDE_LV0_TOT_TIME
                case RIDE_LV0_AVG_SPD
                case RIDE_LV0_MAX_SPD
                case RIDE_LV1_TOT_DIST
                case RIDE_LV1_TOT_TIME
                case RIDE_LV1_AVG_SPD
                case RIDE_LV1_MAX_SPD
                case RIDE_LV2_TOT_DIST
                case RIDE_LV2_TOT_TIME
                case RIDE_LV2_AVG_SPD
                case RIDE_LV2_MAX_SPD
                case RIDE_LV3_TOT_DIST
                case RIDE_LV3_TOT_TIME
                case RIDE_LV3_AVG_SPD
                case RIDE_LV3_MAX_SPD
                case RIDE_LV4_TOT_DIST
                case RIDE_LV4_TOT_TIME
                case RIDE_LV4_AVG_SPD
                case RIDE_LV4_MAX_SPD
                case RIDE_LV5_TOT_DIST
                case RIDE_LV5_TOT_TIME
                case RIDE_LV5_AVG_SPD
                case RIDE_LV5_MAX_SPD
                case RIDE_LV6_TOT_DIST
                case RIDE_LV6_TOT_TIME
                case RIDE_LV6_AVG_SPD
                case RIDE_LV6_MAX_SPD
                case RIDE_LV7_TOT_DIST
                case RIDE_LV7_TOT_TIME
                case RIDE_LV7_AVG_SPD
                case RIDE_LV7_MAX_SPD
                case RIDE_LV8_TOT_DIST
                case RIDE_LV8_TOT_TIME
                case RIDE_LV8_AVG_SPD
                case RIDE_LV8_MAX_SPD
                case RIDE_LV9_TOT_DIST
                case RIDE_LV9_TOT_TIME
                case RIDE_LV9_AVG_SPD
                case RIDE_LV9_MAX_SPD
                case RIDE_LEVEL_ALL
                case KEY_POWER_CNT
                case KEY_UP_CNT
                case KEY_DOWN_CNT
                case KEY_WALK_CNT
                case KEY_LIGHT_CNT
                case KEY_MODE_CNT
                case REC_LT_STATE
                case REC_MAINT_DIST
                case METER_SLEEP_TIME
                case METER_BRIGHT_DAYTIME
                case METER_BRIGHT_NIGHT
                case METER_INIT_LIGHT
                case METER_MAINT_DIST
                case METER_BRIGHT_AUTO_EN
                case METER_BRIGHT_NOW
            }
            
            public enum Bank2: String {
                case TRIP_TOT_DIST
                case TRIP_TOT_TIME
                case TRIP_AVG_SPD
                case TRIP_MAX_SPD
                case TRIP_AVG_CUR
                case TRIP_MAX_CUR
                case TRIP_AVG_CAD_SPD
                case TRIP_MAX_CAD_SPD
                case TRIP_AVG_TORQ
                case TRIP_MAX_TORQ
                case TRIP_AVG_PEDAL_WATT
                case TRIP_MAX_PEDAL_WATT
                case TRIP_AVG_MOTOR_WATT
                case TRIP_MAX_MOTOR_WATT
                case TRIP_CER
                case TRIP_CALORIE
                case TRIP_LEVEL0_TIME
                case TRIP_LEVEL1_TIME
                case TRIP_LEVEL2_TIME
                case TRIP_LEVEL3_TIME
                case TRIP_LEVEL4_TIME
                case TRIP_LEVEL5_TIME
                case TRIP_LEVEL6_TIME
                case TRIP_LEVEL7_TIME
                case TRIP_LEVEL8_TIME
                case TRIP_LEVEL9_TIME
                case DISP_MAINT_MARK_SW
                case DISP_RANGE_SW
                case DISP_UNIT_SW
            }
            
            public enum Bank3: String {
                case FW_PARA_VER
            }
        }
        
        public struct Controller {
            public enum Bank0: String {
                case PRO_SMID
                case PRO_DMID
                case PRO_SSN
                case PRO_DSN
                case PRO_FRAME
                case PRO_SALE_DATE
                case PRO_FW_APP_VER
                case PRO_FW_BTL_VER
                case PRO_FW_SDK_VER
                case PRO_HW_VER
                case PRO_PARA_VER
                case PRO_PROTOCOL_VER
                case PRO_BT_DEV_NAME
                case PRO_MANUFACTURE_DATE
                case PRO_CORE_SDK_VER
                case PRO_CUST_PART_NUM
                case PRO_CUST_PART_NAME
                case PRO_CUST_PROJ_CODE
                case PRO_END_CUST
                case PRO_SUPPLIER
                case PRO_CUST_HW_VER
                case PRO_PROG_SEC
            }
            
            public enum Bank1: String {
                case MAX_ASSIST_LV
                case SPD_MAG_NUM
                case CRUISE_ENABLE
                case SPD_MAX_LIMIT
                case BUSCUR_MAX_MOTOR
                case TH_LV_ENABLE
                case SPD_LIMIT_LV_ENABLE
                case CUR_LIMIT_LV_ENABLE
                case RADIO_LV_ENABLE
                case SOFTSTART_LV_ENABLE
                case TS_UP_FILTER_DELAY
                case TS_DOWN_FILTER_DELAY
                case MOTORPOWER_TS_WEAK
                case ASSIST_AC_SLOPE
                case ASSIST_DE_SLOPE
                case LV1_ASSIST_MAX_CUR
                case LV1_ASSIST_RADIO
                case LV1_ASSIST_MAX_SPD
                case LV1_ASSIST_STA_LV
                case LV2_ASSIST_MAX_CUR
                case LV2_ASSIST_RADIO
                case LV2_ASSIST_MAX_SPD
                case LV2_ASSIST_STA_LV
                case LV3_ASSIST_MAX_CUR
                case LV3_ASSIST_RADIO
                case LV3_ASSIST_MAX_SPD
                case LV3_ASSIST_STA_LV
                case LV4_ASSIST_MAX_CUR
                case LV4_ASSIST_RADIO
                case LV4_ASSIST_MAX_SPD
                case LV4_ASSIST_STA_LV
                case LV5_ASSIST_MAX_CUR
                case LV5_ASSIST_RADIO
                case LV5_ASSIST_MAX_SPD
                case LV5_ASSIST_STA_LV
                case LV6_ASSIST_MAX_CUR
                case LV6_ASSIST_RADIO
                case LV6_ASSIST_MAX_SPD
                case LV6_ASSIST_STA_LV
                case LV7_ASSIST_MAX_CUR
                case LV7_ASSIST_RADIO
                case LV7_ASSIST_MAX_SPD
                case LV7_ASSIST_STA_LV
                case LV8_ASSIST_MAX_CUR
                case LV8_ASSIST_RADIO
                case LV8_ASSIST_MAX_SPD
                case LV8_ASSIST_STA_LV
                case LV9_ASSIST_MAX_CUR
                case LV9_ASSIST_RADIO
                case LV9_ASSIST_MAX_SPD
                case LV9_ASSIST_STA_LV
                case STA_SIGNAL_NUM
                case TS_STA_MODE
                case TS_ZERO_FIND
                case TS_ZERO_VAL
                case TS_STA_ADD_VAL
                case STA_SPD_COMP_MAX
                case STA_SPD_COMP_MIN
                case PEDAL_END_MOTOR_DELAY
                case ASSIST_BRAKE_DE_SLOPE
                case WL_CIRCUMFERENCE
                case BAT_LOW_MIN_POWER
                case GEAR_RADIO_ENABLE
                case FRONT_FLUTED_DISC_STAGE
                case LV1_FRONT_FLUTED_NUM
                case LV2_FRONT_FLUTED_NUM
                case LV3_FRONT_FLUTED_NUM
                case LV4_FRONT_FLUTED_NUM
                case FREEWHEEL_STAGE
                case LV1_FREEWHEEL_NUM
                case LV2_FREEWHEEL_NUM
                case LV3_FREEWHEEL_NUM
                case LV4_FREEWHEEL_NUM
                case LV5_FREEWHEEL_NUM
                case LV6_FREEWHEEL_NUM
                case LV7_FREEWHEEL_NUM
                case LV8_FREEWHEEL_NUM
                case LV9_FREEWHEEL_NUM
                case LV10_FREEWHEEL_NUM
                case LV11_FREEWHEEL_NUM
                case LV12_FREEWHEEL_NUM
                case LV13_FREEWHEEL_NUM
                case LV14_FREEWHEEL_NUM
                case LV15_FREEWHEEL_NUM
                case TS_ZERO_VOLT_GAP
                case CS_STOP_SPD
                case TS_MAX_VOLT
                case TS_MIN_VOLT
                case TS_FAIL_TIME
                case CS_TS_TH
                case CS_SPD_TH
                case CS_FAIL_TIME
            }
            
            public enum Bank2: String {
                case MOTOR_PRO_TEMP
                case MOTOR_REC_TEMP
                case CONTROLLER_PRO_TEMP
                case CONTROLLER_REC_TEMP
                case SUP_ASSIST
                case PEDAL_AST_MODE
                case SUP_MAX_AST_SPD
                case W_AST_SPD
                case W_AST_MAX_CUR
                case W_AST_ACC_DEC
                case T_MIN_VOLT
                case T_MAX_VOLT
                case T_ERR_VOLT
                case T_AC_SLOPE
                case T_DE_SLOPE
                case T_FAIL_TIME_TH
            }
            
            public enum Bank3: String {
                case TOTAL_ODO
                case BACKUP_TOTAL_ODO
                case TOTAL_TIME
                case PRO_CHG_DMID
                case PRO_CHG_DSN
                case PRO_CHG_CSN
                case PRO_MOTOR_DMID
                case PRO_MOTOR_DSN
                case PRO_MOTOR_CSN
                case PRO_TORQUE_DMID
                case PRO_TORQUE_DSN
                case PRO_TORQUE_CSN
                case PRO_FLIGHT_DMID
                case PRO_FLIGHT_DSN
                case PRO_FLIGHT_CSN
                case PRO_RLIGHT_DMID
                case PRO_RLIGHT_DSN
                case PRO_RLIGHT_CSN
                case PRO_THROTTLE_DMID
                case PRO_THROTTLE_DSN
                case PRO_THROTTLE_CSN
            }
        }
        
        public struct BMS1 {
            public enum Bank0: String {
                case PRO_SMID
                case PRO_DMID
                case PRO_SSN
                case PRO_DSN
                case PRO_FRAME
                case PRO_SALE_DATE
                case PRO_FW_APP_VER
                case PRO_FW_BTL_VER
                case PRO_FW_SDK_VER
                case PRO_HW_VER
                case PRO_PARA_VER
                case PRO_PROTOCOL_VER
                case PRO_BT_DEV_NAME
                case PRO_MANUFACTURE_DATE
                case PRO_CORE_SDK_VER
                case PRO_CUST_PART_NUM
                case PRO_CUST_PART_NAME
                case PRO_CUST_PROJ_CODE
                case PRO_END_CUST
                case PRO_SUPPLIER
                case PRO_CUST_HW_VER
                case PRO_PROG_SEC
            }
            
            public enum Bank1: String {
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
                case GMT_TIME_HR
            }
            
            public enum Bank3: String {
                case BAT_VOLT
                case BAT_LOW_VOLT
                case BAT_UNDER_VOLT
                case LAST_CC_YEAR
                case LAST_CC_MONTH
                case LAST_CC_DAY
                case SECOND_LAST_CC_YEAR
                case SECOND_LAST_CC_MONTH
                case SECOND_LAST_CC_DAY
                case LAST_DISC_YEAR
                case LAST_DISC_MONTH
                case LAST_DISC_DAY
                case LAST_DISC_HR
                case LAST_DISC_MIN
                case LAST_DISC_SEC
                case CCI_FCC_TIME
                case CCI_OVER_70_TIME
                case CCI_OVER_15_TIME
                case CELL_LAST_STORAGE_CAP
                case DIS_ACCUMULATION_MAH
                case LAST_CC_VOLT
                case LAST_CC_CAPACITY
                case SECOND_LAST_CC_VOLT
                case SECOND_LAST_CC_CAPACITY
                case LAST_DISC_VOLT
                case LAST_DISC_CAPACITY
            }
        }
        
        public struct BMS2 {  // reserved
            
        }
        
        public enum Integrated: String {
            case HMI_BANK0
            case HMI_BANK2
            case BATTERY_BANK0
            case CONTROLLER_BANK0
            /// 並沒有完整讀取整個 Bank 。
            case CONTROLLER_BANK1
            case CONTROLLER_BANK1_LV1_ASSIST
            case CONTROLLER_BANK1_LV2_ASSIST
            case CONTROLLER_BANK1_LV3_ASSIST
            case CONTROLLER_BANK1_LV4_ASSIST
            case CONTROLLER_BANK1_LV5_ASSIST
            case CONTROLLER_BANK1_LV6_ASSIST
            case CONTROLLER_BANK1_LV7_ASSIST
            case CONTROLLER_BANK1_LV8_ASSIST
            case CONTROLLER_BANK1_LV9_ASSIST
            /// 並沒有完整讀取整個 Bank 。
            case CONTROLLER_BANK3
        }
    }
}
