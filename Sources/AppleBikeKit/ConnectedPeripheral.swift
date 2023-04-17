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

public struct ConnectedPeripheral {
    
    public private(set) lazy var currentPeripheral: CurrentValueSubject<BluetoothPeripheral?, Never> = {
        .init(nil)
    }()
    
    public private(set) lazy var writeCharacteristic: CurrentValueSubject<BluetoothCharacteristic?, Never> = {
        .init(nil)
    }()
    
    public private(set) lazy var writeWithoutResponseCharacteristic: CurrentValueSubject<BluetoothCharacteristic?, Never> = {
        .init(nil)
    }()
    
    public private(set) lazy var notifyCharacteristic: CurrentValueSubject<BluetoothCharacteristic?, Never> = {
        .init(nil)
    }()
    
    public mutating func reset() {
        self.currentPeripheral.value = nil
        self.writeCharacteristic.value = nil
        self.writeWithoutResponseCharacteristic.value = nil
        self.notifyCharacteristic.value = nil
    }
}
