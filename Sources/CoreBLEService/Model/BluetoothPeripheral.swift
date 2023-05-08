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
    
    var rssi: Float?
    
    public var deviceName: String?
    
    var localName: String?
    
    var uuid: String?
    
    var services: [BluetoothService] {
        self.device.services?.map({ .init(service: $0) }) ?? .init()
    }
    
    var address: String {
        self.device.identifier.uuidString
    }
    
    public func setNotifyValue(_ enabled: Bool, for characteristic: CBCharacteristic) {
        self.device.setNotifyValue(enabled, for: characteristic)
    }
    
    public func writeValue(_ data: Data, for characteristic: CBCharacteristic) {
        guard let type: CharacteristicWriteType = .init(rawValue: characteristic.uuid.uuidString) else { return }
        self.device.writeValue(data, for: characteristic, type: type == .write ? .withResponse : .withoutResponse)
    }
}
