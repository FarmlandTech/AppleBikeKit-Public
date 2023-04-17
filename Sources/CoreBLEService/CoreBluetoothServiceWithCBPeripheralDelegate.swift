//
//  File.swift
//  
//
//  Created by Yves Tsai on 2023/3/29.
//

import Foundation
import CoreBluetooth

extension CoreBluetoothService: CBPeripheralDelegate {
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Swift.Error?) {
        if let error: Swift.Error {
            print("AppleBikeKit[DiscoverServices]: \(error)")
            return
        }
        
        peripheral.services?.forEach { service in
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Swift.Error?) {
        if let error: Swift.Error {
            print("AppleBikeKit[DiscoverCharacteristics]: \(error)")
            return
        }
        
        BluetoothPeripheral(device: peripheral).services.forEach { service in
            service.characteristics.forEach { characteristic in
                let uuid: String = characteristic.characteristic.uuid.uuidString
                print("AppleBikeKit[DiscoverCharacteristics]: \(uuid)")
            }
        }
        
        self.characteristicsSubject.send(peripheral)
        
        BluetoothService(service: service).characteristics.forEach { characteristic in
            peripheral.discoverDescriptors(for: characteristic.characteristic)
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: Swift.Error?) {
        if let error: Swift.Error {
            print("AppleBikeKit[DiscoverDescriptors]: \(error)")
            return
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Swift.Error?) {
        if let error: Swift.Error {
            print("AppleBikeKit[UpdateValueForCharacteristic]: \(error)")
            return
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor descriptor: CBDescriptor, error: Swift.Error?) {
        if let error: Swift.Error {
            print("AppleBikeKit[UpdateValueForDescriptor]: \(error)")
            return
        }
    }
    
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
    
    public func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Swift.Error?) {
        if let error: Swift.Error {
            print("AppleBikeKit[ReadRSSI]: \(error)")
            return
        }
        
        self.rssiSubject.send(RSSI)
    }
}
