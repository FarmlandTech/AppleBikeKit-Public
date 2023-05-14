//
//  File.swift
//
//
//  Created by Yves Tsai on 2023/3/28.
//

import Foundation
import CoreBluetooth
import Combine

public enum CharacteristicWriteType: String {
    case write = "46610010-726D-6C61-6E64-546563685457"
    case notify = "46610011-726D-6C61-6E64-546563685457"
    case writeWithoutResponse = "46610020-726D-6C61-6E64-546563685457"
}

public class CoreBluetoothService: NSObject {
    
    enum Error: Swift.Error {
        case wrongManagerState(CBManagerState)
    }
    
    /// 藍牙連線狀態。
    public enum PeripheralStatus {
        /// 未知。
        case unknown
        /// 未連線。
        case didConnect
        /// 已連線。
        case didDisconnect
        /// 已進入準備狀態。(可被操作)
        case prepared
    }
    
    private var serviceUUID: String?
    
    private lazy var centralManager: CBCentralManager = {
        .init(delegate: self, queue: .main)
    }()
    
    public override init() {
        super.init()
        _ = self.centralManager
    }
    
    public private(set) lazy var stateSubject: CurrentValueSubject<CBManagerState, Never> = {
        .init(.unknown)
    }()
    
    public private(set) lazy var scanningSubject: CurrentValueSubject<Bool, Never> = {
        .init(false)
    }()
    
    public private(set) lazy var foundDevicesSubject: CurrentValueSubject<Array<(peripheral: BluetoothPeripheral, date: Date)>, Never> = {
        .init(.init())
    }()
    
    public private(set) lazy var peripheralSubject: CurrentValueSubject<(PeripheralStatus, BluetoothPeripheral?), Never> = {
        let defaultValue: (PeripheralStatus, BluetoothPeripheral?) = (.unknown, nil)
        return .init(defaultValue)
    }()
    
    public private(set) lazy var characteristicsSubject: CurrentValueSubject<CBPeripheral?, Never> = {
        .init(nil)
    }()
    
    public private(set) lazy var didUpdateValueForCharacteristicsSubject: CurrentValueSubject<BluetoothCharacteristic?, Never> = {
        .init(nil)
    }()
    
    public private(set) lazy var didWriteValueForCharacteristicsSubject: CurrentValueSubject<BluetoothCharacteristic?, Never> = {
        .init(nil)
    }()
    
    public private(set) lazy var rssiSubject: CurrentValueSubject<NSNumber?, Never> = {
        .init(nil)
    }()
    
    public func startScanning() throws {
        // 判斷裝置的藍芽狀態。
        guard self.centralManager.state == .poweredOn else {
            throw CoreBluetoothService.Error.wrongManagerState(self.centralManager.state)
        }
        
        // 如果已經連線狀態，就不用執行了。
        guard !self.scanningSubject.value else { return }
        
        // 刷新當前的掃描狀態。
        self.scanningSubject.value = true
        
        // 執行任務。
        let options: [String : Any] = [CBCentralManagerScanOptionAllowDuplicatesKey: true]
        if let serviceUUID: String {
            let uuid: CBUUID = .init(string: serviceUUID)
            self.centralManager.scanForPeripherals(withServices: [uuid], options: options)
        } else {
            self.centralManager.scanForPeripherals(withServices: nil, options: options)
        }
    }
    
    public func stopScanning() {
        // 如果已經離線狀態，就不用執行了。
        guard self.scanningSubject.value else { return }
        
        // 刷新當前的掃描狀態。
        self.scanningSubject.value = false
        
        // 執行任務。
        self.centralManager.stopScan()
    }
    
    public func connect(peripheral: BluetoothPeripheral) {
        self.centralManager.connect(peripheral.device)
    }
    
    public func disconnect(peripheral: BluetoothPeripheral) {
        self.serviceUUID = nil
        self.centralManager.cancelPeripheralConnection(peripheral.device)
    }
}
