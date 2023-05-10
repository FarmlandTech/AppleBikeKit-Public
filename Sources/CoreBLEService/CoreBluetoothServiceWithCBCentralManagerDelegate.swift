//
//  File.swift
//  
//
//  Created by Yves Tsai on 2023/3/29.
//

import Foundation
import CoreBluetooth

extension String {
    
    /// 對於 AdvertisementData 存取的鍵值的枚舉。
    public enum AdvertisementDataRetrievalKey {
        /// 廣播名稱。
        case localName
        /// 製造商相關的數據。
        case manufacturerData
        /// 裝置的服務的 UUID 。
        case serviceUUIDsKey
        /// 裝置是否可被連接。
        case isConnectable
    }
    
    /// 從 CBCentralManagerDelegate 掃描到的裝置，存取廣播參數的鍵值。
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
    
    /// 從 CBCentralManagerDelegate 掃描到的裝置廣播，轉換為可以直接使用的型態。
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
    
    /// 掃描到的藍牙裝置，取得其廣播名稱。
    fileprivate var localName: String? {
        self[.localName] as? String
    }
    
    /// 掃描到的藍牙裝置，取得其服務的 UUID 的值。
    fileprivate var uuids: [String]? {
        self[.serviceUUIDsKey] as? [String]
    }
}

// MARK: - CBCentralManagerDelegate

extension CoreBluetoothService: CBCentralManagerDelegate {
    
    // 監聽行動裝置的藍牙狀態改變。
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("AppleBikeKit[UpdateState]: \(central.state)")
        self.stateSubject.send(central.state)
    }
    
    // 監聽掃描到的藍牙裝置。
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        guard self.scanningSubject.value, peripheral.name != nil else { return }
        
        let usedAdvertisementData: [String.AdvertisementDataRetrievalKey: Any] = advertisementData.used
        
        let device: BluetoothPeripheral = .init(device: peripheral,
                                                rssi: RSSI.floatValue,
                                                deviceName: usedAdvertisementData.localName,
                                                uuid: usedAdvertisementData.uuids?.first)
        
        var peripherals: [(peripheral: BluetoothPeripheral, date: Date)] = self.foundDevicesSubject.value
        
        if let _ = peripherals.first(where: { $0.peripheral.address == device.address }) {
            for index in stride(from: 0, through: peripherals.count - 1, by: 1) {
                guard peripherals[index].peripheral.address == device.address else { continue }
                peripherals[index] = (device, Date())
            }
        } else {
            peripherals.append((device, Date()))
        }
        
        for (index, element) in peripherals.enumerated() {
            guard Date().timeIntervalSince1970 - element.date.timeIntervalSince1970 >= 2 else { continue }
            peripherals.remove(at: index)
        }
        
        self.foundDevicesSubject.send(peripherals)
    }
    
    // 監聽藍牙裝置的連線。
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("AppleBikeKit[ConnectPeripheral]: \(String(describing: peripheral.name))")
        
        peripheral.delegate = self
        peripheral.discoverServices(nil)
        
        let bluetoothPeripheral: BluetoothPeripheral = .init(device: peripheral)
        self.peripheralSubject.value = (.didConnect, bluetoothPeripheral)
    }
    
    // 監聽藍牙裝置的斷線。
    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Swift.Error?) {
        print("AppleBikeKit[DisconnectPeripheral]: \(String(describing: peripheral.name))")
        
        let bluetoothPeripheral: BluetoothPeripheral = .init(device: peripheral)
        self.peripheralSubject.value = (.didDisconnect, bluetoothPeripheral)
    }
}
