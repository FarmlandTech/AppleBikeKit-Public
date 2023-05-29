//
//  CoreBluetoothService.swift
//
//
//  Created by Yves Tsai on 2023/3/28.
//

import Foundation
import CoreBluetooth
import Combine

public class CoreBluetoothService: NSObject {
    
    private var serviceUUID: String?
    
    // 可透過 CBCentralManager.authorization 或 self.centralManager.authorization 取得當前用戶對藍牙的授權狀態。
    public private(set) lazy var centralManager: CBCentralManager = {
        .init(
            delegate: self,
            queue: .global(),
            // centralManager 建構時，如果行動裝置藍牙沒有開啟，系統會顯示彈窗提醒用戶。
            // 如果想要自己實作彈窗(或提示的方式)，可以將下列值改為 false 。
            options: [CBCentralManagerOptionShowPowerAlertKey: true]
        )
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
    
    public private(set) lazy var peripheralSubject: CurrentValueSubject<PeripheralStatus, Never> = {
        .init(.unknown)
    }()
    
    public private(set) lazy var characteristicsSubject: CurrentValueSubject<CBPeripheral?, Never> = {
        .init(nil)
    }()
    
    public private(set) lazy var didUpdateValueForCharacteristicsSubject: CurrentValueSubject<CBCharacteristic?, Never> = {
        .init(nil)
    }()
    
    public private(set) lazy var didWriteValueForCharacteristicsSubject: CurrentValueSubject<CBCharacteristic?, Never> = {
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
            // 如果不確定要連結哪個藍牙裝置，則在 withServices 參數填入 nil 即可。
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

// MARK: - 行動裝置與藍牙裝置的連線狀態

extension CoreBluetoothService {
    
    /// 藍牙連線狀態。
    public enum PeripheralStatus {
        /// 未知。
        case unknown
        /// 未連線。
        case didConnect(BluetoothPeripheral)
        /// 已連線。
        case didDisconnect(BluetoothPeripheral)
        /// 已進入準備狀態。(可被操作)
        case prepared
    }
}

// MARK: - 操作 CoreBluetooth 時所遭遇的錯誤

extension CoreBluetoothService {
    
    /// CoreBluetoothService 操作 CoreBluetooth 時所遭遇的錯誤
    enum Error: Swift.Error {
        /// 行動裝置的藍牙狀態錯誤。
        case wrongManagerState(CBManagerState)
    }
}

// MARK: - 通訊的特徵值

extension CoreBluetoothService {
    
    /// 通訊的特徵值
    public enum CharacteristicWriteType: String {
        /// 寫入。(有回傳值)
        case write = "46610010-726D-6C61-6E64-546563685457"
        /// 寫入。(無回傳值)
        case writeWithoutResponse = "46610020-726D-6C61-6E64-546563685457"
        /// 廣播。
        case notify = "46610011-726D-6C61-6E64-546563685457"
    }
}
