//
//  File.swift
//  
//
//  Created by Yves Tsai on 2023/3/28.
//

import Foundation
import Combine
import CoreBluetooth

import CoreBLEService

/// 藍牙連線統一的對外接口，整合 CoreSDK 與 CoreBLEService 的調用。
public final class AppleBikeKit {
    
    /// 資料流的訂閱。
    private var subscriptions: Set<AnyCancellable> = .init()
    
    /// 當前連線裝置的實例緩存。
    public private(set) lazy var connectedPeripheral: ConnectedPeripheral = {
        .init()
    }()
    
    /// 單例。
    public static let shared: AppleBikeKit = .init()
    
    /// 建構子。
    private init() {
        // 監聽特徵，確認連線狀態。
        self.characteristicsPublisher.sink(receiveValue: { peripheral in
            // 取得每個服務。
            self.connectedPeripheral.currentPeripheral.value?.device.services?.forEach({ [weak self] service in
                guard let self: AppleBikeKit else { return }
                guard let characteristics: [CBCharacteristic] = service.characteristics else { return }
                // 取得每個服務的所有特徵。
                characteristics.forEach { [weak self] characteristic in
                    guard let self: AppleBikeKit else { return }
                    guard let type: CharacteristicWriteType = .init(rawValue: characteristic.uuid.uuidString) else { return }
                    // 判斷特徵型態，並緩存。
                    switch type {
                    case .write:
                        self.connectedPeripheral.writeCharacteristic.value = BluetoothCharacteristic(characteristic: characteristic)
                    case .notify:
                        self.connectedPeripheral.notifyCharacteristic.value = BluetoothCharacteristic(characteristic: characteristic)
                        self.connectedPeripheral.currentPeripheral.value?.setNotifyValue(true, for: characteristic)
                    case .writeWithoutResponse:
                        self.connectedPeripheral.writeWithoutResponseCharacteristic.value = BluetoothCharacteristic(characteristic: characteristic)
                    }
                }
            })
            
        }).store(in: &self.subscriptions)
    }
    
    /// 解構子。
    deinit {
        self.subscriptions.forEach { $0.cancel() }
    }
    
    // MARK: - CoreBluetoothService
    
    /// 操作 CoreBluetooth 的物件實例。
    private let coreBluetoothService: CoreBluetoothService = .init()
    
    /// 連線狀態的發佈者。
    public private(set) lazy var statePublisher: AnyPublisher<CBManagerState, Never> = {
        self.coreBluetoothService.stateSubject.eraseToAnyPublisher()
    }()
    
    /// 是否為掃描中的發佈者。
    public private(set) lazy var scanningPublisher: AnyPublisher<Bool, Never> = {
        self.coreBluetoothService.scanningSubject.eraseToAnyPublisher()
    }()
    
    /// 掃描到的裝置的發佈者。
    public private(set) lazy var foundDevicesPublisher: AnyPublisher<Array<BluetoothPeripheral>, Never> = {
        self.coreBluetoothService.foundDevicesSubject
            .map({ peripherals in
                peripherals.filter({
                    $0.deviceName != nil && ($0.deviceName!.hasPrefix("FL") || $0.deviceName!.hasPrefix("Farmland"))
                })
            })
            .eraseToAnyPublisher()
    }()
    
    /// 已連線裝置的發佈者。(包含其連線狀態與斷線狀態)
    public private(set) lazy var peripheralPublisher: AnyPublisher<(CoreBluetoothService.PeripheralStatus, BluetoothPeripheral?), Never> = {
        self.coreBluetoothService.peripheralSubject.eraseToAnyPublisher()
    }()
    
    /// 已搜尋到特徵的發佈者。
    public private(set) lazy var characteristicsPublisher: AnyPublisher<CBPeripheral?, Never> = {
        self.coreBluetoothService.characteristicsSubject
            .filter({ $0?.identifier == self.connectedPeripheral.currentPeripheral.value?.device.identifier })
            .eraseToAnyPublisher()
    }()
    
    /**
     當前連線裝置 RSSI 的發佈者。
     
     - Precondition: 需要調用 `readRSSI()` 方法，才會取得數值。
     */
    public private(set) lazy var rssiPublisher: AnyPublisher<NSNumber?, Never> = {
        self.coreBluetoothService.rssiSubject.eraseToAnyPublisher()
    }()
    
    /**
     開始掃描藍牙裝置。
     
     - Throws: 如果行動裝置的藍牙為未開啟狀態，則拋出錯誤。
     */
    public func startScan() throws {
        try self.coreBluetoothService.startScanning()
    }
    
    /**
     停止掃描藍牙裝置。
     */
    public func stopScan() {
        self.coreBluetoothService.stopScanning()
    }
    
    /**
     對於藍牙裝置進行連結。
     
     - parameter bluetoothPeripheral: 欲進行連結的目標藍牙裝置。
     */
    public func connect(_ bluetoothPeripheral: BluetoothPeripheral) {
        self.connectedPeripheral.currentPeripheral.value = bluetoothPeripheral
        self.coreBluetoothService.connect(peripheral: bluetoothPeripheral)
    }
    
    /**
     對於藍牙裝置斷開連結。
     
     - parameter bluetoothPeripheral: 欲斷開連結的目標藍牙裝置。
     */
    public func disconnect(_ bluetoothPeripheral: BluetoothPeripheral) {
        self.connectedPeripheral.reset()
        self.coreBluetoothService.disconnect(peripheral: bluetoothPeripheral)
    }
    
    /**
     讀取藍牙裝置的 RSSI 值。
     
     - Precondition: 對於當前連結的藍牙裝置，讀取 RSSI 值。
     - Precondition: 此方法，呼叫一次，僅會得到一次回傳值，並非連續性的監聽。
     */
    public func readRSSI() {
        self.connectedPeripheral.currentPeripheral.value?.device.readRSSI()
    }
    
    // MARK: - CoreSDKService
}
