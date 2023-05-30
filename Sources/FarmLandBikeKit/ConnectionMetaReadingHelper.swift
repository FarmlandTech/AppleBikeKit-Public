//
//  ConnectionMetaReadingHelper.swift
//  
//
//  Created by Yves Tsai on 2023/5/26.
//

import Foundation
import Combine

import CoreSDKService

public struct MetaParameter {
    public fileprivate(set) var hmiSSN: String?
    public fileprivate(set) var hmiDMID: String?
    public fileprivate(set) var hmiDSN: String?
    public fileprivate(set) var hmiSMID: String?
    public fileprivate(set) var hmiDistanceUint: Bool?
    public fileprivate(set) var batterySSN: String?
    public fileprivate(set) var batteryDMID: String?
    public fileprivate(set) var batteryDSN: String?
    public fileprivate(set) var batterySMID: String?
    public fileprivate(set) var controllerSSN: String?
    public fileprivate(set) var controllerDMID: String?
    public fileprivate(set) var controllerDSN: String?
    public fileprivate(set) var controllerSMID: String?
}

extension MetaParameter: Equatable {
    fileprivate var isHMIOmit: Bool {
        self.hmiSSN == nil || self.hmiDMID == nil || self.hmiDSN == nil || self.hmiSMID == nil
    }
    
    fileprivate var isDistanceUintOmit: Bool {
        self.hmiDistanceUint == nil
    }
    
    fileprivate var isBatteryOmit: Bool {
        self.batterySSN == nil || self.batteryDMID == nil || self.batteryDSN == nil || self.batterySMID == nil
    }
    
    fileprivate var isControllerOmit: Bool {
        self.controllerSSN == nil || self.controllerDMID == nil || self.controllerDSN == nil || self.controllerSMID == nil
    }
    
    public var isOmit: Bool {
        self.isHMIOmit || self.isDistanceUintOmit || self.isBatteryOmit || self.isControllerOmit
    }
    
    public static func == (lhs: Self, rhs: Self) -> Bool {
        if lhs.isOmit || rhs.isOmit {
            return false
        }
        let isHmiEqual: Bool = lhs.hmiSSN == rhs.batterySSN && lhs.hmiDMID == rhs.hmiDMID && lhs.hmiDSN == rhs.hmiDSN && lhs.hmiSMID == rhs.hmiSMID && lhs.hmiDistanceUint == rhs.hmiDistanceUint
        let isBatteryEqual: Bool = lhs.batterySSN == rhs.batterySSN && lhs.batteryDMID == rhs.batteryDMID && lhs.batteryDSN == rhs.batteryDSN && lhs.batterySMID == rhs.batterySMID
        let isControllerEqual: Bool = lhs.controllerSSN == rhs.controllerSSN && lhs.controllerDMID == rhs.controllerDMID && lhs.controllerDSN == rhs.controllerDSN && lhs.controllerSMID == rhs.controllerSMID
        return isHmiEqual && isBatteryEqual && isControllerEqual
    }
}

final public class ConnectionMetaReadingHelper {
    
    private lazy var subscriptions: Set<AnyCancellable> = {
        .init()
    }()
    
    public private(set) lazy var metaSubject: CurrentValueSubject<MetaParameter, Never> = {
        .init(.init())
    }()
    
    private var taskNames: [ParameterData.Name] = [
        .INTEGRATED_HMI_BANK0,
        .DISP_UNIT_SW,
        .INTEGRATED_BATTERY_BANK0,
        .INTEGRATED_CONTROLLER_BANK0
    ]
    
    init() {
        // 對個別參數，進行訂閱。
        for name in self.taskNames {
            if FarmLandBikeKit.sleipnir.parameterDataRepository.integratedParameters.contains(where: { $0.name == name }) {
                let index: Int? = FarmLandBikeKit.sleipnir.parameterDataRepository.parameters.firstIndex(where: { $0.name == name })
                guard let index: Int else { continue }
                guard let dividedParameters: [ParameterData] = FarmLandBikeKit.sleipnir.parameterDataRepository.parameters[index].dividedParameters else { continue }
                for parameterData in dividedParameters {
                    self.sink(parameterData.name)
                }
            } else {
                self.sink(name)
            }
        }
    }
    
    deinit {
        // 取消訂閱。
        self.subscriptions.forEach({ $0.cancel() })
    }
    
    /// 對個別參數，進行監聽。
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
            case .ControllerSSN:
                self.metaSubject.value.controllerSSN = output as? String
            case .ControllerDMID:
                self.metaSubject.value.controllerDMID = output as? String
            case .ControllerDSN:
                self.metaSubject.value.controllerDSN = output as? String
            case .ControllerSMID:
                self.metaSubject.value.controllerSMID = output as? String
            default:
                return
            }
            guard !self.metaSubject.value.isOmit else { return }
        }).store(in: &self.subscriptions)
    }
    
    func doTask() throws {
        // 校正電控時間
        self.recurUpdateClock()
        // 取得參數
        try self.recurFetchMeta()
    }
    
    private func recurUpdateClock() {
        // TODO: 未實作！
        
    }
    
    private func recurFetchMeta() throws {
        for name in self.taskNames {
            if name == .INTEGRATED_HMI_BANK0, !self.metaSubject.value.isHMIOmit { continue }
            if name == .DISP_UNIT_SW, !self.metaSubject.value.isDistanceUintOmit { continue }
            if name == .INTEGRATED_BATTERY_BANK0, !self.metaSubject.value.isBatteryOmit { continue }
            if name == .INTEGRATED_CONTROLLER_BANK0, !self.metaSubject.value.isControllerOmit { continue }
            try FarmLandBikeKit.sleipnir.readParameter(name: name)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            guard self.metaSubject.value.isOmit else { return }
            try? self.recurFetchMeta()
        }
    }
}
