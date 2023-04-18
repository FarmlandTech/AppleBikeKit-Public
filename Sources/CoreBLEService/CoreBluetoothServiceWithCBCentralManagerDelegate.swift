//
//  File.swift
//  
//
//  Created by Yves Tsai on 2023/3/29.
//

import Foundation
import CoreBluetooth

extension String {
    public enum AdvertisementDataRetrievalKey {
        case localName
        case manufacturerData
        case serviceUUIDsKey
        case isConnectable
    }
    
    fileprivate var advertisementDataRetrievalKey: AdvertisementDataRetrievalKey? {
        switch self {
        case "kCBAdvDataIsConnectable":
            return .isConnectable
        case "kCBAdvDataLocalName":
            return .localName
        case "kCBAdvDataManufacturerData":
            return .manufacturerData
        case "kCBAdvDataServiceUUIDs":
            return .serviceUUIDsKey
        default:
            return nil
        }
    }
}

extension Dictionary where Key == String, Value == Any {
    
    fileprivate var used: [String.AdvertisementDataRetrievalKey: Any] {
        var results: [String.AdvertisementDataRetrievalKey: Any] = .init()
        
        for (key, value) in self {
            switch key.advertisementDataRetrievalKey {
            case .none:
                break
            case .some(let advertisementDataRetrievalKey):
                switch advertisementDataRetrievalKey {
                case .serviceUUIDsKey:
                    guard let serviceUUIDs: [CBUUID] = value as? [CBUUID] else { continue }
                    let identifiers: [String] = serviceUUIDs.map { $0.uuidString }
                    results.updateValue(identifiers, forKey: advertisementDataRetrievalKey)
                case .manufacturerData:
                    guard let data: Data = value as? Data else { continue }
                    results.updateValue(data, forKey: advertisementDataRetrievalKey)
                default:
                    results.updateValue(value, forKey: advertisementDataRetrievalKey)
                }
            }
        }
        
        return results
    }
}

extension Dictionary where Key == String.AdvertisementDataRetrievalKey, Value == Any {
    
    fileprivate var localName: String? {
        self[.localName] as? String
    }
    
    fileprivate var uuids: [String]? {
        self[.serviceUUIDsKey] as? [String]
    }
}

extension CoreBluetoothService: CBCentralManagerDelegate {
    
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("AppleBikeKit[UpdateState]: \(central.state)")
        self.stateSubject.send(central.state)
    }
    
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        guard self.scanningSubject.value, peripheral.name != nil else { return }
        
        let usedAdvertisementData: [String.AdvertisementDataRetrievalKey: Any] = advertisementData.used
        
        let device: BluetoothPeripheral = .init(device: peripheral,
                                                rssi: RSSI.floatValue,
                                                deviceName: usedAdvertisementData.localName,
                                                uuid: usedAdvertisementData.uuids?.first)
        
        if let foundDevice = self.foundDevicesSubject.value.first(where: { $0.address == device.address }) {
            for index in stride(from: 0, through: self.foundDevicesSubject.value.count - 1, by: 1) {
                guard self.foundDevicesSubject.value[index].address == device.address else { continue }
                self.foundDevicesSubject.value[index] = foundDevice
            }
        } else {
            self.foundDevicesSubject.value.append(device)
        }
    }
    
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("AppleBikeKit[ConnectPeripheral]: \(String(describing: peripheral.name))")
        
        peripheral.delegate = self
        peripheral.discoverServices(nil)
        
        let bluetoothPeripheral: BluetoothPeripheral = .init(device: peripheral)
        self.peripheralSubject.value = (.didConnect, bluetoothPeripheral)
    }
    
    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Swift.Error?) {
        print("AppleBikeKit[DisconnectPeripheral]: \(String(describing: peripheral.name))")
        
        let bluetoothPeripheral: BluetoothPeripheral = .init(device: peripheral)
        self.peripheralSubject.value = (.didDisconnect, bluetoothPeripheral)
    }
}
