//
//  File.swift
//  
//
//  Created by Yves Tsai on 2023/3/28.
//

import Foundation
import CoreBluetooth
import Combine

enum AdvertisementDataRetrievalKey {
    case localName
    case manufacturerData
    case serviceUUIDsKey
    case isConnectable
}

protocol CoreBluetoothServiceDelegate {
    
    typealias BluetoothCharacteristic = CBDescriptor
    
    func didDiscoverDevice(peripheral: BluetoothPeripheral, data: [AdvertisementDataRetrievalKey: Any])
    
    func didConnect(peripheral: BluetoothPeripheral)
    
    func didDisconnect(peripheral: BluetoothPeripheral)
    
    func didDiscoverServices(peripheral: BluetoothPeripheral)
    
    func didDiscoverCharacteristics(peripheral: BluetoothPeripheral)
    
    func didCharacteristicsValueChanged(peripheral: BluetoothPeripheral, characteristic: BluetoothCharacteristic)
    
    func didRssiUpdate(peripheral: BluetoothPeripheral)
    
    func didUpdateMTU(peripheral: BluetoothPeripheral)
    
    func didReadDescriptor(peripheral: BluetoothPeripheral, descriptor: BluetoothCharacteristic)
    
    func didWriteDescriptor(peripheral: BluetoothPeripheral, descriptor: BluetoothCharacteristic)
    
    func didWriteCharacteristic(peripheral: BluetoothPeripheral, characteristic: BluetoothCharacteristic)
}

class CoreBluetoothService: NSObject {
    
    enum Error: Swift.Error {
        case wrongManagerState(CBManagerState)
    }
    
    private var servuceUUID: String?
    
    private lazy var centralManager: CBCentralManager = {
        .init(delegate: self, queue: .main)
    }()
    
    var delegates: [CoreBluetoothServiceDelegate] = .init()
    
    let statePublisher: CurrentValueSubject<CBManagerState, Never> = .init(.unknown)
    
    let scanningPublisher: CurrentValueSubject<Bool, Never> = .init(false)
    
    func startScanning() throws {
        // 判斷裝置的藍芽狀態。
        guard self.centralManager.state == .poweredOn else {
            throw CoreBluetoothService.Error.wrongManagerState(self.centralManager.state)
        }
        
        // 如果已經連線狀態，就不用執行了。
        guard self.scanningPublisher.value else { return }
        
        // 刷新當前的掃描狀態。
        self.scanningPublisher.value = true
        
        // 執行任務。
        let options: [String : Any] = [CBCentralManagerScanOptionAllowDuplicatesKey: true]
        if let servuceUUID {
            let uuid: CBUUID = .init(string: servuceUUID)
            self.centralManager.scanForPeripherals(withServices: [uuid], options: options)
        } else {
            self.centralManager.scanForPeripherals(withServices: nil, options: options)
        }
    }
    
    func stopScanning() {
        // 如果已經離線狀態，就不用執行了。
        guard !self.scanningPublisher.value else { return }
        
        // 刷新當前的掃描狀態。
        self.scanningPublisher.value = false
        
        // 執行任務。
        self.centralManager.stopScan()
    }
    
    func connect(peripheral: BluetoothPeripheral) {
        self.centralManager.connect(peripheral.device)
    }
    
    func disconnect(peripheral: BluetoothPeripheral) {
        self.centralManager.cancelPeripheralConnection(peripheral.device)
    }
}

extension CoreBluetoothService: CBCentralManagerDelegate {
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        self.statePublisher.send(central.state)
        print("AppleBikeKit: \(central.state)")
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        guard self.scanningPublisher.value, let name: String = peripheral.name else { return }
        
        let device: BluetoothPeripheral = .init(device: peripheral, rssi: RSSI.floatValue)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        
    }
}

