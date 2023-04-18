//
//  File.swift
//  
//
//  Created by Yves Tsai on 2023/4/14.
//

import Foundation
import Combine
import CoreBluetooth

import CoreBLEService

/// 連線的裝置實例緩存。
public struct ConnectedPeripheral {
    
    /// 當前連線的裝置。
    public private(set) lazy var currentPeripheral: CurrentValueSubject<BluetoothPeripheral?, Never> = {
        .init(nil)
    }()
    
    /// 寫入的特徵。
    public private(set) lazy var writeCharacteristic: CurrentValueSubject<BluetoothCharacteristic?, Never> = {
        .init(nil)
    }()
    
    /// 寫入(但無回應)的特徵。
    public private(set) lazy var writeWithoutResponseCharacteristic: CurrentValueSubject<BluetoothCharacteristic?, Never> = {
        .init(nil)
    }()
    
    /// 廣播的特徵。
    public private(set) lazy var notifyCharacteristic: CurrentValueSubject<BluetoothCharacteristic?, Never> = {
        .init(nil)
    }()
    
    /**
     斷線時，重置連線的實例，清空緩存。
     */
    public mutating func reset() {
        self.currentPeripheral.value = nil
        self.writeCharacteristic.value = nil
        self.writeWithoutResponseCharacteristic.value = nil
        self.notifyCharacteristic.value = nil
    }
}
