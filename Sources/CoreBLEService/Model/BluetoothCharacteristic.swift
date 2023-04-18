//
//  File.swift
//  
//
//  Created by Yves Tsai on 2023/3/28.
//

import Foundation
import CoreBluetooth

public struct BluetoothCharacteristic {
    
    public let characteristic: CBCharacteristic
    
    public init(characteristic: CBCharacteristic) {
        self.characteristic = characteristic
    }
}
