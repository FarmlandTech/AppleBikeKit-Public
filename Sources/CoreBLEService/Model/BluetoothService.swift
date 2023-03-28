//
//  File.swift
//  
//
//  Created by Yves Tsai on 2023/3/28.
//

import Foundation
import CoreBluetooth

struct BluetoothService {
    
    let service: CBService
    
    var name: String {
        self.service.uuid.uuidString
    }
    
    var characteristics: [BluetoothCharacteristic] {
        self.service.characteristics?.map({ .init(characteristic: $0) }) ?? .init()
    }
}
