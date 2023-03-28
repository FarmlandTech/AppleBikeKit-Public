//
//  File.swift
//  
//
//  Created by Yves Tsai on 2023/3/28.
//

import Foundation
import CoreBluetooth

struct BluetoothPeripheral {
    
    let device: CBPeripheral
    
    var rssi: Float?
    
    var deviceName: String?
    
    var localName: String?
    
    var uuid: String?
    
    var services: [BluetoothService] {
        self.device.services?.map({ .init(service: $0) }) ?? .init()
    }
    
    var address: String {
        self.device.identifier.uuidString
    }
}
