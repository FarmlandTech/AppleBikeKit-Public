//
//  File.swift
//
//
//  Created by Yves Tsai on 2023/3/28.
//

import Foundation
import CoreBluetooth
import Combine

public enum AdvertisementDataRetrievalKey {
    case localName
    case manufacturerData
    case serviceUUIDsKey
    case isConnectable
}

public protocol CoreBluetoothServiceDelegate {
    
    typealias BluetoothCharacteristicDescriptor = CBDescriptor
    
    func didDiscoverServices(peripheral: BluetoothPeripheral)
    
    func didDiscoverCharacteristics(peripheral: BluetoothPeripheral)
    
    func didCharacteristicsValueChanged(peripheral: BluetoothPeripheral, characteristic: BluetoothCharacteristic)
    
    func didRssiUpdate(peripheral: BluetoothPeripheral)
    
    func didUpdateMTU(peripheral: BluetoothPeripheral)
    
    func didReadDescriptor(peripheral: BluetoothPeripheral, descriptor: BluetoothCharacteristicDescriptor)
    
    func didWriteDescriptor(peripheral: BluetoothPeripheral, descriptor: BluetoothCharacteristicDescriptor)
    
    func didWriteCharacteristic(peripheral: BluetoothPeripheral, characteristic: BluetoothCharacteristic)
}

public class CoreBluetoothService: NSObject {
    
    enum Error: Swift.Error {
        case wrongManagerState(CBManagerState)
    }
    
    public enum PeripheralStatus {
        case didConnect, didDisconnect
    }
    
    private var servuceUUID: String?
    
    private lazy var centralManager: CBCentralManager = {
        .init(delegate: self, queue: .main)
    }()
    
    public var delegates: [CoreBluetoothServiceDelegate] = .init()
    
    public let statePublisher: CurrentValueSubject<CBManagerState, Never> = .init(.unknown)
    
    public let scanningPublisher: CurrentValueSubject<Bool, Never> = .init(false)
    
    public let foundDevicesPublisher: CurrentValueSubject<Array<BluetoothPeripheral>, Never> = .init(.init())
    
    public let peripheralPublisher: CurrentValueSubject<(PeripheralStatus, BluetoothPeripheral)?, Never> = .init(nil)
    
    public func initCentralManager() -> CoreBluetoothService {
        _ = self.centralManager
        return self
    }
    
    public func startScanning() throws {
        // 判斷裝置的藍芽狀態。
        guard self.centralManager.state == .poweredOn else {
            throw CoreBluetoothService.Error.wrongManagerState(self.centralManager.state)
        }
        
        // 如果已經連線狀態，就不用執行了。
        guard !self.scanningPublisher.value else { return }
        
        // 刷新當前的掃描狀態。
        self.scanningPublisher.value = true
        
        // 執行任務。
        let options: [String : Any] = [CBCentralManagerScanOptionAllowDuplicatesKey: true]
        if let servuceUUID: String {
            let uuid: CBUUID = .init(string: servuceUUID)
            self.centralManager.scanForPeripherals(withServices: [uuid], options: options)
        } else {
            self.centralManager.scanForPeripherals(withServices: nil, options: options)
        }
    }
    
    public func stopScanning() {
        // 如果已經離線狀態，就不用執行了。
        guard self.scanningPublisher.value else { return }
        
        // 刷新當前的掃描狀態。
        self.scanningPublisher.value = false
        
        // 執行任務。
        self.centralManager.stopScan()
    }
    
    public func connect(peripheral: BluetoothPeripheral) {
        self.centralManager.connect(peripheral.device)
    }
    
    public func disconnect(peripheral: BluetoothPeripheral) {
        self.centralManager.cancelPeripheralConnection(peripheral.device)
    }
}


