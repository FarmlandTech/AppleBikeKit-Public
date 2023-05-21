//
//  File.swift
//  
//
//  Created by Yves Tsai on 2023/3/28.
//

import Foundation
import CoreBluetooth

public struct BluetoothPeripheral {
    
    public let device: CBPeripheral
    
    public var rssi: Float?
    
    public var deviceName: String?
    
    public var localName: String?
    
    public var uuid: String?
    
    public var address: String {
        self.device.identifier.uuidString
    }
    
    public func writeValue(_ data: Data, for characteristic: CBCharacteristic) {
        let type: CoreBluetoothService.CharacteristicWriteType? = .init(rawValue: characteristic.uuid.uuidString)
        switch type {
        case .none:
            break
        case .some(.write):
            self.device.writeValue(data, for: characteristic, type: .withResponse)
        case .some(.writeWithoutResponse):
            self.device.writeValue(data, for: characteristic, type: .withoutResponse)
        case .some(.notify):
            break
        }
    }
}
