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
    
    private lazy var connectionMetaReadingHelper: ConnectionMetaReadingHelper = {
        .init()
    }()
    
    public private(set) lazy var metaPublisher: AnyPublisher<MetaParameter, Never> = {
        self.connectionMetaReadingHelper.metaSubject.removeDuplicates().eraseToAnyPublisher()
    }()
    
    private override init() {
        super.init()
        // 監聽連線狀態。
        self.peripheralPublisher.sink(receiveValue: { status in
            switch status {
            case .unknown, .didConnect(_):
                break
            case .didDisconnect(_):
                // TODO: 把緩存的參數重置！！！
                break
            case .prepared:
                try? self.connectionMetaReadingHelper.doTask()
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
        self.connectionMetaReadingHelper.metaSubject.send(.init())
        self.disconnect(peripheral)
    }
}
