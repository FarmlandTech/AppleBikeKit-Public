//
//  ConnectionMetaReadingHelper.swift
//  
//
//  Created by Yves Tsai on 2023/5/26.
//

import Foundation
import Combine

import CoreSDKSourceCode
import CoreSDKService

/// 緩存關鍵參數的物件。
public struct MetaParameter {
    
    public enum EnablePart: Equatable {
        case hmi
        case controller
        case battery
        case display
        case motor
        case cadenceSensor
        case torqueSensor
        case charger
        case frontLight
        case rearLight
        case throttle
        case eBrake
        case eLock
        case frontDerailleur
        case rearDerailleur
        case IoT
        case undefined(Int)
        
        public var warningCodes: [Int] {
            guard let deviceInfo: FL_Info_st = FarmLandBikeKit.sleipnir.info.deviceInfo else {
                return .init()
            }
            switch self {
            case .hmi:
                return deviceInfo.warningCodes.filter({ $0.tranfer2WarningCodeType == .hmi })
            case .controller:
                return deviceInfo.warningCodes.filter({ $0.tranfer2WarningCodeType == .controller })
            case .display:
                return .init()
            case .motor:
                return deviceInfo.warningCodes.filter({ $0.tranfer2WarningCodeType == .motor })
            case .cadenceSensor:
                return .init()
            case .torqueSensor:
                return deviceInfo.warningCodes.filter({ $0.tranfer2WarningCodeType == .torque })
            case .charger:
                return .init()
            case .frontLight, .rearLight:
                return deviceInfo.warningCodes.filter({ $0.tranfer2WarningCodeType == .light })
            case .throttle:
                return deviceInfo.warningCodes.filter({ $0.tranfer2WarningCodeType == .throttle })
            case .eBrake:
                return .init()
            case .eLock:
                return .init()
            case .frontDerailleur, .rearDerailleur:
                return deviceInfo.warningCodes.filter({ $0.tranfer2WarningCodeType == .derailleur })
            case .IoT:
                return .init()
            default:
                return deviceInfo.warningCodes.filter({ $0.tranfer2WarningCodeType == .unknown })
            }
        }
        
        public var errorCodes: [Int] {
            guard let deviceInfo: FL_Info_st = FarmLandBikeKit.sleipnir.info.deviceInfo else {
                return .init()
            }
            switch self {
            case .hmi:
                return deviceInfo.errorCodes.filter({ $0.tranfer2ErrorCodeType == .hmi })
            case .controller:
                return deviceInfo.errorCodes.filter({ $0.tranfer2ErrorCodeType == .controller })
            case .display:
                return .init()
            case .motor:
                return deviceInfo.errorCodes.filter({ $0.tranfer2ErrorCodeType == .motor })
            case .cadenceSensor:
                return .init()
            case .torqueSensor:
                return deviceInfo.errorCodes.filter({ $0.tranfer2ErrorCodeType == .torque })
            case .charger:
                return .init()
            case .frontLight, .rearLight:
                return deviceInfo.errorCodes.filter({ $0.tranfer2ErrorCodeType == .light })
            case .throttle:
                return deviceInfo.errorCodes.filter({ $0.tranfer2ErrorCodeType == .throttle })
            case .eBrake:
                return .init()
            case .eLock:
                return .init()
            case .frontDerailleur, .rearDerailleur:
                return deviceInfo.errorCodes.filter({ $0.tranfer2ErrorCodeType == .derailleur })
            case .IoT:
                return .init()
            default:
                return deviceInfo.errorCodes.filter({ $0.tranfer2ErrorCodeType == .unknown })
            }
        }
        
        public static func == (lhs: Self, rhs: Self) -> Bool {
            if case .hmi = lhs, case .hmi = rhs {
                return true
            } else if case .controller = lhs, case .controller = rhs {
                return true
            } else if case .battery = lhs, case .battery = rhs {
                return true
            } else if case .display = lhs, case .display = rhs {
                return true
            } else if case .motor = lhs, case .motor = rhs {
                return true
            } else if case .cadenceSensor = lhs, case .cadenceSensor = rhs {
                return true
            } else if case .torqueSensor = lhs, case .torqueSensor = rhs {
                return true
            } else if case .charger = lhs, case .charger = rhs {
                return true
            } else if case .frontLight = lhs, case .frontLight = rhs {
                return true
            } else if case .rearLight = lhs, case .rearLight = rhs {
                return true
            } else if case .throttle = lhs, case .throttle = rhs {
                return true
            } else if case .eBrake = lhs, case .eBrake = rhs {
                return true
            } else if case .eLock = lhs, case .eLock = rhs {
                return true
            } else if case .frontDerailleur = lhs, case .frontDerailleur = rhs {
                return true
            } else if case .rearDerailleur = lhs, case .rearDerailleur = rhs {
                return true
            } else if case .IoT = lhs, case .IoT = rhs {
                return true
            } else if case .undefined(let lhsPosition) = lhs, case .undefined(let rhsPosition) = rhs, lhsPosition == rhsPosition {
                return true
            } else {
                return false
            }
        }
    }
    
    public fileprivate(set) var hmiSSN: String?
    public fileprivate(set) var hmiDMID: String?
    public fileprivate(set) var hmiDSN: String?
    public fileprivate(set) var hmiSMID: String?
    public fileprivate(set) var hmiFrame: String?
    public fileprivate(set) var hmiSaleDate: String?
    public fileprivate(set) var hmiFWAppVer: String?
    public fileprivate(set) var hmiFWBtlVer: String?
    public fileprivate(set) var hmiFWSdkVer: String?
    public fileprivate(set) var hmiHWVer: String?
    public fileprivate(set) var hmiParaVer: String?
    public fileprivate(set) var hmiProtocolVer: String?
    public fileprivate(set) var hmiBtDevName: String?
    
    /// 距離單位為公制或英制。
    public fileprivate(set) var hmiDistanceUint: Bool?
    
    public fileprivate(set) var batterySSN: String?
    public fileprivate(set) var batteryDMID: String?
    public fileprivate(set) var batteryDSN: String?
    public fileprivate(set) var batterySMID: String?
    public fileprivate(set) var batteryFrame: String?
    public fileprivate(set) var batterySaleDate: String?
    public fileprivate(set) var batteryFWAppVer: String?
    public fileprivate(set) var batteryFWBtlVer: String?
    public fileprivate(set) var batteryFWSdkVer: String?
    public fileprivate(set) var batteryHWVer: String?
    public fileprivate(set) var batteryParaVer: String?
    public fileprivate(set) var batteryProtocolVer: String?
    public fileprivate(set) var batteryBtDevName: String?
    
    public fileprivate(set) var controllerSSN: String?
    public fileprivate(set) var controllerDMID: String?
    public fileprivate(set) var controllerDSN: String?
    public fileprivate(set) var controllerSMID: String?
    public fileprivate(set) var controllerFrame: String?
    public fileprivate(set) var controllerSaleDate: String?
    public fileprivate(set) var controllerFWAppVer: String?
    public fileprivate(set) var controllerFWBtlVer: String?
    public fileprivate(set) var controllerFWSdkVer: String?
    public fileprivate(set) var controllerHWVer: String?
    public fileprivate(set) var controllerParaVer: String?
    public fileprivate(set) var controllerProtocolVer: String?
    public fileprivate(set) var controllerBtDevName: String?
    
    internal fileprivate(set) var enablePartRawList: [UInt8]?
    var enableParts: [EnablePart] {
        var result: [EnablePart] = .init()
        if let rawList: [UInt8] = self.enablePartRawList, rawList.count > 1, rawList[0] == 1 {
            result.append(.hmi)
        }
        if let rawList: [UInt8] = self.enablePartRawList, rawList.count > 2, rawList[1] == 1 {
            result.append(.controller)
        }
        if let rawList: [UInt8] = self.enablePartRawList, rawList.count > 3, rawList[2] == 1 {
            result.append(.battery)
        }
        if let rawList: [UInt8] = self.enablePartRawList, rawList.count > 4, rawList[3] == 1 {
            result.append(.display)
        }
        if let rawList: [UInt8] = self.enablePartRawList, rawList.count > 5, rawList[4] == 1 {
            result.append(.motor)
        }
        if let rawList: [UInt8] = self.enablePartRawList, rawList.count > 6, rawList[5] == 1 {
            result.append(.cadenceSensor)
        }
        if let rawList: [UInt8] = self.enablePartRawList, rawList.count > 7, rawList[6] == 1 {
            result.append(.torqueSensor)
        }
        if let rawList: [UInt8] = self.enablePartRawList, rawList.count > 8, rawList[7] == 1 {
            result.append(.charger)
        }
        if let rawList: [UInt8] = self.enablePartRawList, rawList.count > 9, rawList[8] == 1 {
            result.append(.frontLight)
        }
        if let rawList: [UInt8] = self.enablePartRawList, rawList.count > 10, rawList[9] == 1 {
            result.append(.rearLight)
        }
        if let rawList: [UInt8] = self.enablePartRawList, rawList.count > 11, rawList[10] == 1 {
            result.append(.throttle)
        }
        if let rawList: [UInt8] = self.enablePartRawList, rawList.count > 12, rawList[11] == 1 {
            result.append(.eBrake)
        }
        if let rawList: [UInt8] = self.enablePartRawList, rawList.count > 13, rawList[12] == 1 {
            result.append(.eLock)
        }
        if let rawList: [UInt8] = self.enablePartRawList, rawList.count > 14, rawList[13] == 1 {
            result.append(.frontDerailleur)
        }
        if let rawList: [UInt8] = self.enablePartRawList, rawList.count > 15, rawList[14] == 1 {
            result.append(.rearDerailleur)
        }
        if let rawList: [UInt8] = self.enablePartRawList, rawList.count > 16, rawList[15] == 1 {
            result.append(.IoT)
        }
        if let rawList: [UInt8] = self.enablePartRawList, rawList.count > 17, rawList[16] == 1 {
            result.append(.undefined(16))
        }
        if let rawList: [UInt8] = self.enablePartRawList, rawList.count > 18, rawList[17] == 1 {
            result.append(.undefined(17))
        }
        if let rawList: [UInt8] = self.enablePartRawList, rawList.count > 19, rawList[18] == 1 {
            result.append(.undefined(18))
        }
        if let rawList: [UInt8] = self.enablePartRawList, rawList.count > 20, rawList[19] == 1 {
            result.append(.undefined(19))
        }
        if let rawList: [UInt8] = self.enablePartRawList, rawList.count > 21, rawList[20] == 1 {
            result.append(.undefined(20))
        }
        if let rawList: [UInt8] = self.enablePartRawList, rawList.count > 22, rawList[21] == 1 {
            result.append(.undefined(21))
        }
        if let rawList: [UInt8] = self.enablePartRawList, rawList.count > 23, rawList[22] == 1 {
            result.append(.undefined(22))
        }
        if let rawList: [UInt8] = self.enablePartRawList, rawList.count > 24, rawList[23] == 1 {
            result.append(.undefined(23))
        }
        if let rawList: [UInt8] = self.enablePartRawList, rawList.count > 25, rawList[24] == 1 {
            result.append(.undefined(24))
        }
        if let rawList: [UInt8] = self.enablePartRawList, rawList.count > 26, rawList[25] == 1 {
            result.append(.undefined(25))
        }
        if let rawList: [UInt8] = self.enablePartRawList, rawList.count > 27, rawList[26] == 1 {
            result.append(.undefined(26))
        }
        if let rawList: [UInt8] = self.enablePartRawList, rawList.count > 28, rawList[27] == 1 {
            result.append(.undefined(27))
        }
        if let rawList: [UInt8] = self.enablePartRawList, rawList.count > 29, rawList[28] == 1 {
            result.append(.undefined(28))
        }
        if let rawList: [UInt8] = self.enablePartRawList, rawList.count > 30, rawList[29] == 1 {
            result.append(.undefined(29))
        }
        if let rawList: [UInt8] = self.enablePartRawList, rawList.count > 31, rawList[30] == 1 {
            result.append(.undefined(30))
        }
        if let rawList: [UInt8] = self.enablePartRawList, rawList.count > 32, rawList[31] == 1 {
            result.append(.undefined(31))
        }
        return result
    }
}

extension MetaParameter: Equatable {
    /// HMI 的參數是否有缺失。
    fileprivate var isHMIOmit: Bool {
        self.hmiSSN == nil || self.hmiDMID == nil || self.hmiDSN == nil || self.hmiSMID == nil
    }
    
    /// '距離單位是否為公制或英制'的參數是否有缺失。
    fileprivate var isDistanceUintOmit: Bool {
        self.hmiDistanceUint == nil
    }
    
    /// 電池的參數是否有缺失。
    fileprivate var isBatteryOmit: Bool {
        self.batterySSN == nil || self.batteryDMID == nil || self.batteryDSN == nil || self.batterySMID == nil
    }
    
    /// 控制器的參數是否有缺失。
    fileprivate var isControllerOmit: Bool {
        self.controllerSSN == nil || self.controllerDMID == nil || self.controllerDSN == nil || self.controllerSMID == nil
    }
    
    fileprivate var isEnablePartsOmit: Bool {
        self.enablePartRawList == nil
    }
    
    /// 參數(HMI 、距離單位、電池與控制器)是否有缺失。
    public var isOmit: Bool {
        self.isHMIOmit || self.isDistanceUintOmit || self.isControllerOmit || self.isEnablePartsOmit
    }
    
    public static func == (lhs: Self, rhs: Self) -> Bool {
        if lhs.isOmit || rhs.isOmit {
            return false
        }
        let isHmiEqual: Bool = lhs.hmiSSN == rhs.hmiSSN && lhs.hmiDMID == rhs.hmiDMID && lhs.hmiDSN == rhs.hmiDSN && lhs.hmiSMID == rhs.hmiSMID && lhs.hmiDistanceUint == rhs.hmiDistanceUint
        let isBatteryEqual: Bool = lhs.batterySSN == rhs.batterySSN && lhs.batteryDMID == rhs.batteryDMID && lhs.batteryDSN == rhs.batteryDSN && lhs.batterySMID == rhs.batterySMID
        let isControllerEqual: Bool = lhs.controllerSSN == rhs.controllerSSN && lhs.controllerDMID == rhs.controllerDMID && lhs.controllerDSN == rhs.controllerDSN && lhs.controllerSMID == rhs.controllerSMID
        let isEnablePartsEqual: Bool = lhs.enablePartRawList == rhs.enablePartRawList
        return isHmiEqual && isBatteryEqual && isControllerEqual && isEnablePartsEqual
    }
}

extension FL_Info_st {
    public func getEnableParts() throws -> [MetaParameter.EnablePart] {
        try FarmLandBikeKit.sleipnir.checkVersion(part: .controller, version: "0.0.22")
        return FarmLandBikeKit.sleipnir.metaParameter.enableParts
    }
}

/// 取得關鍵參數(ssn或dmid等)的處理物件。
final public class ConnectionMetaReadingHelper {
    
    /// 關鍵參數的 Subject 。
    public private(set) lazy var metaSubject: CurrentValueSubject<MetaParameter, Never> = {
        .init(.init())
    }()
    
    /// 訂閱實例。
    private lazy var subscriptions: Set<AnyCancellable> = {
        .init()
    }()
    
    /// 需執行的所有任務陣列。
    private let taskNames: [ParameterData.Name] = [
        .INTEGRATED_HMI_BANK0,
        .DISP_UNIT_SW,
        .INTEGRATED_BATTERY_BANK0,
        .INTEGRATED_CONTROLLER_BANK0,
        .SYS_PART_EN
    ]
    
    /**
     建構子。
     */
    init() {
        // 對個別參數，進行訂閱。
        for name in self.taskNames {
            if FarmLandBikeKit.sleipnir.parameterDataRepository.integratedParameters.contains(where: { $0.name == name }) {
                // 讀取區段參數的流程。
                let index: Int? = FarmLandBikeKit.sleipnir.parameterDataRepository.parameters.firstIndex(where: { $0.name == name })
                guard let index: Int else { continue }
                guard let dividedParameters: [ParameterData] = FarmLandBikeKit.sleipnir.parameterDataRepository.parameters[index].dividedParameters else { continue }
                for parameterData in dividedParameters {
                    self.sink(parameterData.name)
                }
            } else {
                // 讀取單一參數的流程。
                self.sink(name)
            }
        }
    }
    
    /**
     解構子。
     */
    deinit {
        // 取消訂閱。
        self.subscriptions.forEach({ $0.cancel() })
    }
    
    /**
     開始執行任務。
     
     - Note: 會以遞迴的方式，不斷重新嘗試讀取參數，直到所有參數都完備才會停止。
     
     - Throws: 無法以名稱找到參數時，將會拋出 parameterDataNotFoundByName 錯誤。
     - Throws: 無法執行讀取參數命令時，將會拋出 readParameterFail 錯誤。
     */
    public func doTask() throws {
        self.metaSubject.send(.init())
        try self.recurFetchMeta()
    }
    
    /**
     對個別參數，進行監聽。
     
     - parameter name: 參數名稱。
     */
    private func sink(_ name: ParameterData.Name) {
        guard let index: Int = FarmLandBikeKit.sleipnir.parameterDataRepository.parameters.firstIndex(where: { $0.name == name }) else { return }
        FarmLandBikeKit.sleipnir.parameterDataRepository.parameters[index].subject.sink(receiveValue: { [weak self] output in
            guard let self: ConnectionMetaReadingHelper else { return }
            switch name {
            case .HmiSSN:
                self.metaSubject.value.hmiSSN = output as? String
            case .HmiDMID:
                self.metaSubject.value.hmiDMID = output as? String
            case .HmiDSN:
                self.metaSubject.value.hmiDSN = output as? String
            case .HmiSMID:
                self.metaSubject.value.hmiSMID = output as? String
            case .HmiFrame:
                self.metaSubject.value.hmiFrame = output as? String
            case .HmiSaleDate:
                self.metaSubject.value.hmiSaleDate = output as? String
            case .HmiFWAppVer:
                self.metaSubject.value.hmiFWAppVer = output as? String
            case .HmiFWBtlVer:
                self.metaSubject.value.hmiFWBtlVer = output as? String
            case .HmiFWSdkVer:
                self.metaSubject.value.hmiFWSdkVer = output as? String
            case .HmiHWVer:
                self.metaSubject.value.hmiHWVer = output as? String
            case .HmiParaVer:
                self.metaSubject.value.hmiParaVer = output as? String
            case .HmiProtocolVer:
                self.metaSubject.value.hmiProtocolVer = output as? String
            case .HmiBtDevName:
                self.metaSubject.value.hmiBtDevName = output as? String
            case .DISP_UNIT_SW:
                guard let value: Int = output as? Int else { return }
                var isMetricSystem: Bool?
                if value == 0 {
                    isMetricSystem = true
                } else if value == 1 {
                    isMetricSystem = false
                }
                guard let isMetricSystem: Bool else { return }
                self.metaSubject.value.hmiDistanceUint = isMetricSystem
            case .BattSSN:
                self.metaSubject.value.batterySSN = output as? String
            case .BattDMID:
                self.metaSubject.value.batteryDMID = output as? String
            case .BattDSN:
                self.metaSubject.value.batteryDSN = output as? String
            case .BattSMID:
                self.metaSubject.value.batterySMID = output as? String
            case .BattFrame:
                self.metaSubject.value.batteryFrame = output as? String
            case .BattSaleDate:
                self.metaSubject.value.batterySaleDate = output as? String
            case .BattFWAppVer:
                self.metaSubject.value.batteryFWAppVer = output as? String
            case .BattFWBtlVer:
                self.metaSubject.value.batteryFWBtlVer = output as? String
            case .BattFWSdkVer:
                self.metaSubject.value.batteryFWSdkVer = output as? String
            case .BattHWVer:
                self.metaSubject.value.batteryHWVer = output as? String
            case .BattParaVer:
                self.metaSubject.value.batteryParaVer = output as? String
            case .BattProtocolVer:
                self.metaSubject.value.batteryProtocolVer = output as? String
            case .BattBtDevName:
                self.metaSubject.value.batteryBtDevName = output as? String
            case .ControllerSSN:
                self.metaSubject.value.controllerSSN = output as? String
            case .ControllerDMID:
                self.metaSubject.value.controllerDMID = output as? String
            case .ControllerDSN:
                self.metaSubject.value.controllerDSN = output as? String
            case .ControllerSMID:
                self.metaSubject.value.controllerSMID = output as? String
            case .ControllerFrame:
                self.metaSubject.value.controllerFrame = output as? String
            case .ControllerSaleDate:
                self.metaSubject.value.controllerSaleDate = output as? String
            case .ControllerFWAppVer:
                self.metaSubject.value.controllerFWAppVer = output as? String
            case .ControllerFWBtlVer:
                self.metaSubject.value.controllerFWBtlVer = output as? String
            case .ControllerFWSdkVer:
                self.metaSubject.value.controllerFWSdkVer = output as? String
            case .ControllerHWVer:
                self.metaSubject.value.controllerHWVer = output as? String
            case .ControllerParaVer:
                self.metaSubject.value.controllerParaVer = output as? String
            case .ControllerProtocolVer:
                self.metaSubject.value.controllerProtocolVer = output as? String
            case .ControllerBtDevName:
                self.metaSubject.value.controllerBtDevName = output as? String
            case .SYS_PART_EN:
                self.metaSubject.value.enablePartRawList = output as? [UInt8]
            default:
                return
            }
        }).store(in: &self.subscriptions)
    }
    
    /**
     讀取參數的任務，具體執行內容。
     
     - Throws: 無法以名稱找到參數時，將會拋出 parameterDataNotFoundByName 錯誤。
     - Throws: 無法執行讀取參數命令時，將會拋出 readParameterFail 錯誤。
     */
    private func recurFetchMeta() throws {
        for name in self.taskNames {
            if name == .INTEGRATED_HMI_BANK0, !self.metaSubject.value.isHMIOmit { continue }
            if name == .DISP_UNIT_SW, !self.metaSubject.value.isDistanceUintOmit { continue }
            if name == .INTEGRATED_BATTERY_BANK0, !self.metaSubject.value.isBatteryOmit { continue }
            if name == .INTEGRATED_CONTROLLER_BANK0, !self.metaSubject.value.isControllerOmit { continue }
            if name == .SYS_PART_EN, !self.metaSubject.value.isEnablePartsOmit { continue }
            try FarmLandBikeKit.sleipnir.readParameter(name: name)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.7) {
            guard self.metaSubject.value.isOmit else { return }
            try? self.recurFetchMeta()
        }
    }
}
