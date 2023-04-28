//
//  File.swift
//  
//
//  Created by Yves Tsai on 2023/3/28.
//

import Foundation
import CoreBluetooth

/// 對 CoreBluetooth 的 CBService 進行封裝。
struct BluetoothService {
    
    /// 緩存 CBService 的實例。
    let service: CBService
    
    /// 取得服務所擁有的特徵陣列，並直接映射為 BluetoothCharacteristic 型態。
    var characteristics: [BluetoothCharacteristic] {
        self.service.characteristics?.map({ .init(characteristic: $0) }) ?? .init()
    }
}
