//
//  ConnectedPeripheral.swift
//  
//
//  Created by Yves Tsai on 2023/4/14.
//

import Foundation
import Combine
import CoreBluetooth

import CoreBLEServiceSourceCode

/// 連線的裝置實例緩存。
public class ConnectedPeripheral {
    
    private var subscriptions: Set<AnyCancellable> = .init()
    
    public var currentPeripheral: BluetoothPeripheral? {
        self.currentPeripheralSubject.value
    }
    
    /// 當前連線的裝置。
    public private(set) lazy var currentPeripheralSubject: CurrentValueSubject<BluetoothPeripheral?, Never> = {
        .init(nil)
    }()
    
    /// 寫入的特徵。
    public private(set) lazy var writeCharacteristicSubject: CurrentValueSubject<CBCharacteristic?, Never> = {
        .init(nil)
    }()
    
    /// 寫入(但無回應)的特徵。
    public private(set) lazy var writeWithoutResponseCharacteristicSubject: CurrentValueSubject<CBCharacteristic?, Never> = {
        .init(nil)
    }()
    
    /// 廣播的特徵。
    public private(set) lazy var notifyCharacteristicSubject: CurrentValueSubject<CBCharacteristic?, Never> = {
        .init(nil)
    }()
    
    init() {
        self.currentPeripheralSubject.sink(receiveValue: { _ in
            
        }).store(in: &self.subscriptions)
        self.writeCharacteristicSubject.sink(receiveValue: { _ in
            
        }).store(in: &self.subscriptions)
        self.writeWithoutResponseCharacteristicSubject.sink(receiveValue: { _ in
            
        }).store(in: &self.subscriptions)
        self.notifyCharacteristicSubject.sink(receiveValue: { _ in
            
        }).store(in: &self.subscriptions)
    }
    
    deinit {
        self.subscriptions.forEach({ $0.cancel() })
    }
    
    /**
     斷線時，重置連線的實例，清空緩存。
     */
    public func reset() {
        self.currentPeripheralSubject.send(nil)
        self.writeCharacteristicSubject.send(nil)
        self.writeWithoutResponseCharacteristicSubject.send(nil)
        self.notifyCharacteristicSubject.send(nil)
    }
}
