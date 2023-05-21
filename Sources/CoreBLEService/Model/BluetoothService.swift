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
}
