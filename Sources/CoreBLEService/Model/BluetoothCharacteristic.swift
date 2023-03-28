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
    
    public var name: String? {
        self.characteristic.uuid.uuidString
    }
    
    public var value: Data? {
        self.characteristic.value
    }
    
    public var descriptors: [CBDescriptor]? {
        self.characteristic.descriptors
    }
}
