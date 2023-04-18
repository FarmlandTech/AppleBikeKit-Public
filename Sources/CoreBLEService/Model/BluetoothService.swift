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
    
    var characteristics: [BluetoothCharacteristic] {
        self.service.characteristics?.map({ .init(characteristic: $0) }) ?? .init()
    }
}
