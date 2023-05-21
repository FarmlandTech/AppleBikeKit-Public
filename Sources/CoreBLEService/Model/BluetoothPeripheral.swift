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
        guard let type: CharacteristicWriteType = .init(rawValue: characteristic.uuid.uuidString) else { return }
        switch type {
        case .write:
            self.device.writeValue(data, for: characteristic, type: .withResponse)
        case .writeWithoutResponse:
            self.device.writeValue(data, for: characteristic, type: .withoutResponse)
        case .notify:
            break
        }
    }
}
