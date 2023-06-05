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
    
    /// 關鍵參數(ssn或dmid等)的緩存值。
    public var metaParameter: MetaParameter {
        self.connectionMetaReadingHelper.metaSubject.value
    }
    
    /// 訂閱實例。
    private lazy var subscriptions: Set<AnyCancellable> = {
        .init()
    }()
    
    /// 取得關鍵參數(ssn或dmid等)的處理物件實例。
    private lazy var connectionMetaReadingHelper: ConnectionMetaReadingHelper = {
        .init()
    }()
    
    /// 更新電控時間的處理物件實例。
    private lazy var systemTimeUpdateHelper: SystemTimeUpdateHelper = {
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
}
