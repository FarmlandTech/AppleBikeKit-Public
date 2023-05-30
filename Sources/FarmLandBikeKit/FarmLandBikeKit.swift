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
    
    public static let sleipnir: FarmLandBikeKit = .init()
    
    private lazy var subscriptions: Set<AnyCancellable> = {
        .init()
    }()
    
    public var metaParameter: MetaParameter {
        self.connectionMetaReadingHelper.metaSubject.value
    }
    
    public private(set) lazy var metaPublisher: AnyPublisher<MetaParameter, Never> = {
        self.connectionMetaReadingHelper.metaSubject.removeDuplicates().eraseToAnyPublisher()
    }()
    
    private lazy var connectionMetaReadingHelper: ConnectionMetaReadingHelper = {
        .init()
    }()
    
    private lazy var systemTimeUpdateHelper: SystemTimeUpdateHelper = {
        .init()
    }()
    
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
    
    deinit {
        self.subscriptions.forEach({ $0.cancel() })
    }
    
    public func connectBike(_ peripheral: BluetoothPeripheral) {
        self.connect(peripheral)
    }
    
    public func disconnectBike() {
        guard let peripheral: BluetoothPeripheral = self.connectedPeripheral.currentPeripheral else { return }
        self.disconnect(peripheral)
    }
}
