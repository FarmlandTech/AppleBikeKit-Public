//
//  File.swift
//  
//
//  Created by Yves Tsai on 2023/3/29.
//

import Foundation
import CoreBluetooth

// MARK: - CBPeripheralDelegate

extension CoreBluetoothService: CBPeripheralDelegate {
    
    // 監聽掃描到的藍牙服務。
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Swift.Error?) {
        if let error: Swift.Error {
            print("AppleBikeKit[DiscoverServices]: \(error)")
            return
        }
        
        peripheral.services?.forEach { service in
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    // 監聽掃描到的藍牙服務特徵。
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Swift.Error?) {
        if let error: Swift.Error {
            print("AppleBikeKit[DiscoverCharacteristics]: \(error)")
            return
        }

        self.characteristicsSubject.send(peripheral)
        
        BluetoothService(service: service).characteristics.forEach { characteristic in
            peripheral.discoverDescriptors(for: characteristic.characteristic)
        }
    }
    
    // 監聽對於藍牙裝置寫入參數的事件。
    public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Swift.Error?) {
        if let error: Swift.Error {
            print("AppleBikeKit[WriteValueForCharacteristic]: \(error)")
            return
        }
#warning("寫入參數時會使用，未驗證！")
        let device: BluetoothPeripheral = .init(device: peripheral)
        let _characteristic: BluetoothCharacteristic = .init(characteristic: characteristic)
        
        for delegate in self.delegates {
            delegate.didWriteCharacteristic(peripheral: device, characteristic: _characteristic)
        }
    }
    
    // 監聽特定藍牙裝置的訊號強度。
    // 在此基本上是指連線的藍牙裝置，並且要呼叫 AppleBikeKit 的 readRSSI() 方法，才會在此讀取到數值。
    public func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Swift.Error?) {
        if let error: Swift.Error {
            print("AppleBikeKit[ReadRSSI]: \(error)")
            return
        }
        
        self.rssiSubject.send(RSSI)
    }
}
