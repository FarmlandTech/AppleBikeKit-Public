//
//  CoreBluetoothServiceWithCBCentralManagerDelegate.swift
//  
//
//  Created by Yves Tsai on 2023/3/29.
//

import Foundation
import CoreBluetooth

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
        
        var results: [(peripheral: BluetoothPeripheral, date: Date)] = .init()
        for element in peripherals {
            guard Date().timeIntervalSince1970 - element.date.timeIntervalSince1970 < 2 else { continue }
            results.append(element)
        }
        
        self.foundDevicesSubject.send(results)
    }
    
    // 監聽藍牙裝置的連線。
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("AppleBikeKit[ConnectPeripheral]: \(String(describing: peripheral.name))")
        
        peripheral.delegate = self
        // 如果不確定要搜尋哪個藍牙裝置，則在 withServices 參數填入 nil 即可。
        peripheral.discoverServices(nil)
        
        let bluetoothPeripheral: BluetoothPeripheral = .init(device: peripheral)
        DispatchQueue.main.async {
            self.peripheralSubject.send(.didConnect(bluetoothPeripheral))
        }
    }
    
    // 監聽藍牙裝置的連線。(失敗狀態)
    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Swift.Error?) {
        print("AppleBikeKit[ConnectPeripheralFail]: \(String(describing: peripheral.name))")
        
        peripheral.delegate = nil
        
        let bluetoothPeripheral: BluetoothPeripheral = .init(device: peripheral)
        DispatchQueue.main.async {
            self.peripheralSubject.send(.didDisconnect(bluetoothPeripheral))
        }
    }
    
    // 監聽藍牙裝置的斷線。
    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Swift.Error?) {
        print("AppleBikeKit[DisconnectPeripheral]: \(String(describing: peripheral.name))")
        
        peripheral.delegate = nil
        
        let bluetoothPeripheral: BluetoothPeripheral = .init(device: peripheral)
        DispatchQueue.main.async {
            self.peripheralSubject.send(.didDisconnect(bluetoothPeripheral))
        }
    }
}
