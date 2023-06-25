//
//  FarmLandBikeKit.swift
//  
//
//  Created by Jeff Chiu on 2023/5/21.
//

import Foundation
import Combine
import CoreBLEService

import AppleBikeKit

final public class FarmLandBikeKit: AppleBikeKit {
    
    /// 單例。
    public static let sleipnir: FarmLandBikeKit = .init()
    
    /// 關鍵參數的 Publisher 。
    public private(set) lazy var metaPublisher: AnyPublisher<MetaParameter, Never> = {
        self.connectionMetaReadingHelper.metaSubject.removeDuplicates().eraseToAnyPublisher()
    }()
    
    public private(set) lazy var assistLevelRepositoryReadingPublisher: AnyPublisher<AssistPlanUpdateHelper.ReadingResult<AssistLevelRepository?>, Never> = {
        self.assistPlanUpdateHelper.readingSubject
            .eraseToAnyPublisher()
    }()
    
    public private(set) lazy var assistLevelRepositoryWritingPublisher: AnyPublisher<AssistPlanUpdateHelper.WritingResult<AssistLevelRepository?>, Never> = {
        self.assistPlanUpdateHelper.writingSubject
            .eraseToAnyPublisher()
    }()
    
    /// 關鍵參數(ssn或dmid等)的緩存值。
    public var metaParameter: MetaParameter {
        self.connectionMetaReadingHelper.metaSubject.value
    }
    
    /// 訂閱實例。
    private lazy var subscriptions: Set<AnyCancellable> = {
        .init()
    }()
    
    /// 取得關鍵參數(ssn或dmid等)的處理物件實例。
    public private(set) lazy var connectionMetaReadingHelper: ConnectionMetaReadingHelper = {
        .init()
    }()
    
    /// 更新電控時間的處理物件實例。
    public private(set) lazy var systemTimeUpdateHelper: SystemTimeUpdateHelper = {
        .init()
    }()
    
    /// 更新電控時間的處理物件實例。
    public private(set) lazy var mileageRecordHelper: MileageRecordHelper = {
        .init()
    }()
    
    private lazy var metricSystemManipulateHelper: MetricSystemManipulateHelper = {
        .init()
    }()
    
    private lazy var assistPlanUpdateHelper: AssistPlanUpdateHelper = {
        .init()
    }()

    /**
     建構子。
     */
    private override init() {
        super.init()
        // 監聽連線狀態。
        self.peripheralPublisher.sink(receiveValue: { status in
            switch status {
            case .unknown, .didConnect(_):
                break
            case .didDisconnect(_):  // 清空緩存數據。
                self.connectionMetaReadingHelper.metaSubject.send(.init())
                self.systemTimeUpdateHelper.stateSubject.send(nil)
            case .prepared:  // 取得關鍵參數。
                do {
                    try self.connectionMetaReadingHelper.doTask()
                    try self.systemTimeUpdateHelper.doTask()
                } catch {
                    // TODO: 錯誤處理？
                    assertionFailure("\(error)")
                }
            }
        }).store(in: &self.subscriptions)
        // 監聽裝置資訊。
        self.deviceInfoPublisher.sink(receiveValue: { deviceInfo in
            
        }).store(in: &self.subscriptions)
    }
    
    /**
     解構子。
     */
    deinit {
        self.subscriptions.forEach({ $0.cancel() })
    }
    
    /**
     執行藍牙連線。
     */
    public func connectBike(_ peripheral: BluetoothPeripheral) {
        self.connect(peripheral)
    }
    
    /**
     執行藍牙斷線。
     */
    public func disconnectBike() {
        guard let peripheral: BluetoothPeripheral = self.connectedPeripheral.currentPeripheral else { return }
        self.disconnect(peripheral)
    }
    
    public func writeMetricSystem(_ isMetricSystem: Bool) throws {
        try self.metricSystemManipulateHelper.write(isMetricSystem)
    }
    
    public func readAssistLevel() throws {
        try self.assistPlanUpdateHelper.read()
    }
    
    public func writeAssistLevel(LV1_AST_RATIO: Int, LV2_AST_RATIO: Int, LV3_AST_RATIO: Int) throws {
        try self.assistPlanUpdateHelper.write(
            LV1_MAX_AST_RATIO: LV1_AST_RATIO,
            LV1_MIN_AST_RATIO: LV1_AST_RATIO / 2,
            LV2_MAX_AST_RATIO: LV2_AST_RATIO,
            LV2_MIN_AST_RATIO: LV2_AST_RATIO / 2,
            LV3_MAX_AST_RATIO: LV3_AST_RATIO,
            LV3_MIN_AST_RATIO: LV3_AST_RATIO / 2
        )
    }
}
