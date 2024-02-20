//
//  MetricSystemManipulateHelper.swift
//  
//
//  Created by Yves Tsai on 2023/6/13.
//

import Foundation
import Combine

import CoreSDKService

/// 存取距離單位(公制or英制)座標系統的處理物件。
final public class MetricSystemManipulateHelper {
    
    /// 存取距離單位(公制or英制)座標系統流程中，可能會遭遇到的錯誤。
    enum Error: Swift.Error {
        /// 仍在嘗試重新寫入。
        case isWriteRecursively
    }
    
    /// 是否為公制。
    public var isMetricSystem: Bool? {
        FarmLandBikeKit.sleipnir.metaParameter.hmiDistanceUint
    }
    
    /// 數據流的訂閱實例。
    private lazy var subscribe: AnyCancellable? = { nil }()
    
    /// 重新寫入的次數上限。
    private let writingRecursivelyCountBoundary: Int = 3
    
    /// 重新寫入的嘗試次數。
    private lazy var writingRecursivelyCount: Int = { 0 }()
    
    /// 是否正在嘗試重新寫入。
    private lazy var isWriteRecursively: Bool = { false }() {
        didSet {
            self.writingRecursivelyCount = self.isWriteRecursively ? 1 : 0
        }
    }
    
    /**
     建構子。
     */
    init() {
        self.subscribe = FarmLandBikeKit.sleipnir.writingParameterStatePublisher.sink(receiveValue: { state in
            
        })
    }
    
    /**
     解構子。
     */
    deinit {
        self.subscribe?.cancel()
    }
    
    /**
     設定存取距離單位(公制or英制)座標系統。
     
     - parameter isMetricSystem: 是否為公制。
     - Throws: 上次的寫入仍然在執行(或重試)，便會拋出錯誤；如果底層 AppleBikeKit 寫入參數時，設定錯誤，也可能會拋出錯誤。
     */
    public func write(_ isMetricSystem: Bool) throws {
        guard !self.isWriteRecursively else {
            throw Self.Error.isWriteRecursively
        }
        self.isWriteRecursively = true
        try self.recurWriteValue(isMetricSystem)
    }
    
    /**
     (如果失敗的話)遞迴多次重新嘗試設定距離單位(公制or英制)座標系統。
     
     - parameter isMetricSystem: 是否為公制。
     - Throws: 上次的寫入仍然在執行(或重試)，便會拋出錯誤；如果底層 AppleBikeKit 寫入參數時，設定錯誤，也可能會拋出錯誤。
     */
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
                guard self.writingRecursivelyCount < self.writingRecursivelyCountBoundary else {
                    self.isWriteRecursively = false
                    return
                }
                self.writingRecursivelyCount += 1
                try? self.recurWriteValue(isMetricSystem)
            }
        }
    }
}
