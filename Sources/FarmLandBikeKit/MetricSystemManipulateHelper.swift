//
//  MetricSystemManipulateHelper.swift
//  
//
//  Created by Yves Tsai on 2023/6/13.
//

import Foundation
import Combine

import CoreSDKService

final public class MetricSystemManipulateHelper {
    
    enum Error: Swift.Error {
        case isWriteRecursively
    }
    
    public var isMetricSystem: Bool? {
        FarmLandBikeKit.sleipnir.metaParameter.hmiDistanceUint
    }
    
    private lazy var subscribe: AnyCancellable? = { nil }()
    
    private lazy var writingRecursivelyCount: Int = { 0 }()
    
    private lazy var isWriteRecursively: Bool = { false }() {
        didSet {
            self.writingRecursivelyCount = self.isWriteRecursively ? 1 : 0
        }
    }
    
    init() {
        self.subscribe = FarmLandBikeKit.sleipnir.writingParameterStatePublisher.sink(receiveValue: { state in
            
        })
    }
    
    deinit {
        self.subscribe?.cancel()
    }
    
    public func write(_ isMetricSystem: Bool) throws {
        guard !self.isWriteRecursively else {
            throw Self.Error.isWriteRecursively
        }
        self.isWriteRecursively = true
        try self.recurWriteValue(isMetricSystem)
    }
    
    private func recurWriteValue(_ isMetricSystem: Bool) throws {
        if let _isMetricSystem: Bool = self.isMetricSystem, _isMetricSystem == isMetricSystem {
            self.isWriteRecursively = false
        } else {
            let name: ParameterData.Name = .DISP_UNIT_SW
            try FarmLandBikeKit.sleipnir.writeParameter(name: name, value: isMetricSystem ? 0 : 1)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                try? FarmLandBikeKit.sleipnir.readParameter(name: name)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) { [weak self] in
                guard let self: MetricSystemManipulateHelper else { return }
                guard self.isMetricSystem != isMetricSystem else {
                    self.isWriteRecursively = false
                    return
                }
                guard self.writingRecursivelyCount < 3 else {
                    self.isWriteRecursively = false
                    return
                }
                self.writingRecursivelyCount += 1
                try? self.recurWriteValue(isMetricSystem)
            }
        }
    }
}
