//
//  CoreBluetoothServiceWithCBPeripheralDelegate.swift
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
        
        DispatchQueue.main.async {
            self.peripheralSubject.value = (.prepared, .init(device: peripheral))
        }
    }
    
    // 監聽掃描到的藍牙服務特徵。
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Swift.Error?) {
        if let error: Swift.Error {
            print("AppleBikeKit[DiscoverCharacteristics]: \(error)")
            return
        }
        
        service.characteristics?.forEach { characteristic in
            peripheral.discoverDescriptors(for: characteristic)
        }
        
        DispatchQueue.main.async {
            self.characteristicsSubject.send(peripheral)
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: Swift.Error?) {
        if let error: Swift.Error {
            print("AppleBikeKit[DiscoverDescriptors]: \(error)")
            return
        }
    }
    
    // 監聽對於藍牙裝置寫入參數的事件。(有回應)
    /**
     呼叫 peripheral.readValue(for: <#T##CBCharacteristic#>) 的回調。
     在此的 characteristic.value 便是讀到的參數值。
     ```
     if characteristic.properties.contains(.read) {
         peripheral.readValue(for: <#T##CBCharacteristic#>)
     }
     ```
     如果嘗試讀取不可讀的特徵，便會在此回調得到 error 。
     */
    /**
     收到訂閱的值時，也會調用此回調。
     */
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Swift.Error?) {
        if let error: Swift.Error {
            print("AppleBikeKit[UpdateValueForCharacteristic]: \(error)")
            return
        }
        
        self.didUpdateValueForCharacteristicsSubject.send(characteristic)
    }
    
    /**
     訂閱(或取消訂閱)一個特徵值得時候，會調用此回調。
     ```
     if characteristic.properties.contains(.notify) || characteristic.properties.contains(.indicate) {
         peripheral.setNotifyValue(<#T##Bool#>, for: <#T##CBCharacteristic#>)  // 布林參數，代表開啟或關閉訂閱。
     }
     ```
     */
    public func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Swift.Error?) {
        if let error: Swift.Error {
            print("AppleBikeKit[UpdateNotificationStateForCharacteristic]: \(error)")
            return
        }
    }
    
    // 以 CBCharacteristicWriteType.withResponse 模式發送的回調。
    // 如果以 CBCharacteristicWriteType.withoutResponse 模式發送，便不會收到此回調。
    public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Swift.Error?) {
        if let error: Swift.Error {
            print("AppleBikeKit[WriteValueForCharacteristic]: \(error)")
            return
        }
        
<<<<<<< HEAD
        self.didWriteValueForCharacteristicsSubject.send(characteristic)
=======
        self.didWriteValueForCharacteristicsSubject.send(characteristic
        )
>>>>>>> bd3cc87ffd269d8490304cddae79ef8f8ccadb0f
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
