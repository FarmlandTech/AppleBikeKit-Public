//
//  ConnectionMetaReadingHelper.swift
//  
//
//  Created by Yves Tsai on 2023/5/26.
//

import Foundation
import Combine

import CoreSDKService

/// 緩存關鍵參數的物件。
public struct MetaParameter {
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
    
    /// 參數(HMI 、距離單位、電池與控制器)是否有缺失。
    public var isOmit: Bool {
        self.isHMIOmit || self.isDistanceUintOmit || self.isBatteryOmit || self.isControllerOmit
    }
    
    public static func == (lhs: Self, rhs: Self) -> Bool {
        if lhs.isOmit || rhs.isOmit {
            return false
        }
        let isHmiEqual: Bool = lhs.hmiSSN == rhs.hmiSSN && lhs.hmiDMID == rhs.hmiDMID && lhs.hmiDSN == rhs.hmiDSN && lhs.hmiSMID == rhs.hmiSMID && lhs.hmiDistanceUint == rhs.hmiDistanceUint
        let isBatteryEqual: Bool = lhs.batterySSN == rhs.batterySSN && lhs.batteryDMID == rhs.batteryDMID && lhs.batteryDSN == rhs.batteryDSN && lhs.batterySMID == rhs.batterySMID
        let isControllerEqual: Bool = lhs.controllerSSN == rhs.controllerSSN && lhs.controllerDMID == rhs.controllerDMID && lhs.controllerDSN == rhs.controllerDSN && lhs.controllerSMID == rhs.controllerSMID
        return isHmiEqual && isBatteryEqual && isControllerEqual
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
        .INTEGRATED_CONTROLLER_BANK0
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
    func doTask() throws {
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
            try FarmLandBikeKit.sleipnir.readParameter(name: name)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.7) {
            guard self.metaSubject.value.isOmit else { return }
            try? self.recurFetchMeta()
        }
    }
}
