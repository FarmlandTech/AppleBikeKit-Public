//
//  File.swift
//  
//
//  Created by Yves Tsai on 2023/3/29.
//

import Foundation
import CoreBluetooth

extension String {
    fileprivate var advertisementDataRetrievalKey: AdvertisementDataRetrievalKey? {
        switch self {
        case "kCBAdvDataIsConnectable":
            return AdvertisementDataRetrievalKey.isConnectable
        case "kCBAdvDataLocalName":
            return AdvertisementDataRetrievalKey.localName
        case "kCBAdvDataManufacturerData":
            return AdvertisementDataRetrievalKey.manufacturerData
        case "kCBAdvDataServiceUUIDs":
            return AdvertisementDataRetrievalKey.serviceUUIDsKey
        default:
            return nil
        }
    }
}

extension Dictionary where Key == String, Value == Any {
    
    fileprivate var used: [AdvertisementDataRetrievalKey: Any] {
        var results: [AdvertisementDataRetrievalKey: Any] = .init()
        
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

extension Dictionary where Key == AdvertisementDataRetrievalKey, Value == Any {
    
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
        self.statePublisher.send(central.state)
    }
    
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        guard self.scanningPublisher.value, peripheral.name != nil else { return }
        
        let usedAdvertisementData: [AdvertisementDataRetrievalKey: Any] = advertisementData.used
        
        var device: BluetoothPeripheral = .init(device: peripheral, rssi: RSSI.floatValue)
        device.deviceName = usedAdvertisementData.localName
        device.uuid = usedAdvertisementData.uuids?.first
        
        for delegate in self.delegates {
            delegate.didDiscoverDevice(peripheral: device, data: usedAdvertisementData)
        }
    }
    
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("AppleBikeKit[ConnectPeripheral]: \(String(describing: peripheral.name))")
        
        peripheral.delegate = self
        peripheral.discoverServices(nil)
        
        let device: BluetoothPeripheral = .init(device: peripheral)
        for delegate in self.delegates {
            delegate.didConnect(peripheral: device)
        }
    }
    
    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Swift.Error?) {
        print("AppleBikeKit[DisconnectPeripheral]: \(String(describing: peripheral.name))")
        
        let device: BluetoothPeripheral = .init(device: peripheral)
        for delegate in self.delegates {
            delegate.didDisconnect(peripheral: device)
        }
    }
}
