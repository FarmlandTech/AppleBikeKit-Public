//
//  File.swift
//  
//
//  Created by Yves Tsai on 2023/3/28.
//

import Foundation
import CoreBluetooth

/// 對 CoreBluetooth 的 CBCharacteristic 進行封裝。
public struct BluetoothCharacteristic {
    
    /// 緩存 CBCharacteristic 的實例。
    public let characteristic: CBCharacteristic
    
    /// 建構子。
    public init(characteristic: CBCharacteristic) {
        self.characteristic = characteristic
    }
}
