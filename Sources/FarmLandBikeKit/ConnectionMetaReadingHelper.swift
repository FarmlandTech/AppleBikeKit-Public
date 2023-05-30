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
    public fileprivate(set) var hmiDistanceUint: Bool?
    public fileprivate(set) var batterySSN: String?
    public fileprivate(set) var batteryDMID: String?
    public fileprivate(set) var controllerSSN: String?
    public fileprivate(set) var controllerDMID: String?
    
    fileprivate var isHMIOmit: Bool {
        self.hmiSSN == nil || self.hmiDMID == nil
    }
    
    fileprivate var isDistanceUintOmit: Bool {
        self.hmiDistanceUint == nil
    }
    
    fileprivate var isBatteryOmit: Bool {
        self.batterySSN == nil || self.batteryDMID == nil
    }
    
    fileprivate var isControllerOmit: Bool {
        self.controllerSSN == nil || self.controllerDMID == nil
    }
    
    fileprivate var isOmit: Bool {
        self.isHMIOmit || self.isDistanceUintOmit || self.isBatteryOmit || self.isControllerOmit
    }
}

final public class ConnectionMetaReadingHelper {
    
    private var subscriptions: Set<AnyCancellable> = .init()
    
    private lazy var metaParameter: MetaParameter = {
        .init()
    }()
    
    public private(set) lazy var metaSubject: CurrentValueSubject<MetaParameter, Never> = {
        .init(self.metaParameter)
    }()
    
    private var taskNames: [ParameterData.Name] = [
        .INTEGRATED_HMI_BANK0,
        .DISP_UNIT_SW,
        .INTEGRATED_BATTERY_BANK0,
        .INTEGRATED_CONTROLLER_BANK0
    ]
    
    init() {
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
        self.subscriptions.forEach({ $0.cancel() })
    }
    
    private func sink(_ name: ParameterData.Name) {
        guard let index: Int = FarmLandBikeKit.sleipnir.parameterDataRepository.parameters.firstIndex(where: { $0.name == name }) else { return }
        FarmLandBikeKit.sleipnir.parameterDataRepository.parameters[index].subject.sink(receiveValue: { [weak self] output in
            guard let self: ConnectionMetaReadingHelper else { return }
            switch name {
            case .HmiSSN:
                self.metaParameter.hmiSSN = output as? String
            case .HmiDMID:
                self.metaParameter.hmiDMID = output as? String
            case .DISP_UNIT_SW:
                guard let value: Int = output as? Int else { return }
                var isMetricSystem: Bool?
                if value == 0 {
                    isMetricSystem = true
                } else if value == 1 {
                    isMetricSystem = false
                }
                guard let isMetricSystem: Bool else { return }
                self.metaParameter.hmiDistanceUint = isMetricSystem
            case .BattSSN:
                self.metaParameter.batterySSN = output as? String
            case .BattDMID:
                self.metaParameter.batteryDMID = output as? String
            case .ControllerSSN:
                self.metaParameter.controllerSSN = output as? String
            case .ControllerDMID:
                self.metaParameter.controllerDMID = output as? String
            default:
                return
            }
            guard !self.metaParameter.isOmit else { return }
            self.metaSubject.send(self.metaParameter)
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
            if name == .INTEGRATED_HMI_BANK0, !self.metaParameter.isHMIOmit { continue }
            if name == .DISP_UNIT_SW, !self.metaParameter.isDistanceUintOmit { continue }
            if name == .INTEGRATED_BATTERY_BANK0, !self.metaParameter.isBatteryOmit { continue }
            if name == .INTEGRATED_CONTROLLER_BANK0, !self.metaParameter.isControllerOmit { continue }
            try FarmLandBikeKit.sleipnir.readParameter(name: name)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            guard self.metaParameter.isOmit else { return }
            try? self.recurFetchMeta()
        }
    }
}
