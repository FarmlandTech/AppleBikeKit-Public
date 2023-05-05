//
//  AppleBikeKit.swift
//  
//
//  Created by Yves Tsai on 2023/3/28.
//

import Foundation
import Combine
import CoreBluetooth

import CoreSDK
import CoreSDKService
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
        self.characteristicsPublisher
            .sink(receiveValue: { peripheral in
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
                            self.connectedPeripheral.writeCharacteristic.value = .init(characteristic: characteristic)
                        case .notify:
                            self.connectedPeripheral.notifyCharacteristic.value = .init(characteristic: characteristic)
                            self.connectedPeripheral.currentPeripheral.value?.setNotifyValue(true, for: characteristic)
                        case .writeWithoutResponse:
                            self.connectedPeripheral.writeWithoutResponseCharacteristic.value = .init(characteristic: characteristic)
                        }
                    }
                })
            })
            .store(in: &self.subscriptions)
        
        // 監聽特徵寫入事件，處理廣播參數。
        self.didUpdateValueForCharacteristicsPublisher
            .sink(receiveValue: { [weak self] characteristic in
                guard let self: AppleBikeKit else { return }
                guard let value: Data = characteristic?.characteristic.value else { return }
                self.coreSDKService.commandPacketIn(dataPacket: Array(value))
            })
            .store(in: &self.subscriptions)
        
        // 監聽參數寫入的事件處理。
        self.coreSDKService.commandPacketSubject
            .sink(receiveValue: { output in
                guard let characteristic: BluetoothCharacteristic = self.connectedPeripheral.writeCharacteristic.value else { return }
                self.connectedPeripheral.currentPeripheral.value?.writeValue(.init(output), for: characteristic.characteristic)
            })
            .store(in: &self.subscriptions)
        
        // 監聽更新韌體的事件處理。
        self.coreSDKService.dataPacketSubject
            .sink(receiveValue: { output in
                guard let characteristic: BluetoothCharacteristic = self.connectedPeripheral.writeWithoutResponseCharacteristic.value else { return }
                self.connectedPeripheral.currentPeripheral.value?.writeValue(.init(output), for: characteristic.characteristic)
            })
            .store(in: &self.subscriptions)
        
        // 監聽參數讀取的事件處理。
        self.coreSDKService.rawDataSubject
            .compactMap({ $0 })
            .sink(receiveValue: { rawData in
                do {
                    let repository: ParameterDataRepository = self.coreSDKService.parameterDataRepository
                    var parameterData: ParameterData = try repository.findParameterData(type: rawData.targetDevice,
                                                                                        bank: rawData.bank,
                                                                                        address: rawData.address,
                                                                                        length: rawData.length)
                    if self.parameterDataRepository.integratedParameters.contains(where: { $0.name == parameterData.name }) {
                        let parameterDataList: [ParameterData] = try parameterData.dividIntoMultiParameters(rawData: rawData)
                        for parameterData in parameterDataList {
                            self.parameterDataSubject.send(parameterData)
                        }
                    } else {
                        parameterData.value = try rawData.bytes.convert2Value(type: parameterData.type,
                                                                              length: Int(parameterData.length))
                        self.parameterDataSubject.send(parameterData)
                    }
                } catch {
                    self.parameterDataSubject.send(completion: .failure(error))
                }
            })
            .store(in: &self.subscriptions)
    }
    
    /// 解構子。
    deinit {
        self.subscriptions.forEach { $0.cancel() }
    }
    
    // MARK: - CoreSDKService
    
    /// 操作 CoreSDK 的物件實例。
    private let coreSDKService: CoreSDKService = .init()
    
    /// 腳踏車裝置資訊。(最後一次)
    public var deviceInfo: FL_Info_st? {
        self.coreSDKService.deviceInfoSubject.value
    }
    
    /// 用於 CoreSDK 的參數倉庫，包括定義與緩存，也實作部分的邏輯。
    public var parameterDataRepository: ParameterDataRepository {
        self.coreSDKService.parameterDataRepository
    }
    
    /// 腳踏車裝置資訊的發佈者。
    public private(set) lazy var deviceInfoPublisher: AnyPublisher<FL_Info_st?, Never> = {
        self.coreSDKService.deviceInfoSubject
            .throttle(for: .milliseconds(700), scheduler: RunLoop.main, latest: true)
            .eraseToAnyPublisher()
    }()
    
    /// 讀取參數時，電控回傳數據的發佈者。
    private let parameterDataSubject: PassthroughSubject<ParameterData, Swift.Error> = .init()
    
    /// 腳踏車裝置讀取來的參數的發佈者。
    public private(set) lazy var parameterDataPubisher: AnyPublisher<ParameterData, Swift.Error> = {
        self.parameterDataSubject.eraseToAnyPublisher()
    }()
    
    /// 寫入參數時，執行狀態的發佈者。
    public private(set) lazy var writingParameterStatePublisher: AnyPublisher<Bool?, Never> = {
        self.coreSDKService.writingParameterStateSubject.eraseToAnyPublisher()
    }()
    
    /// 重啟部件時，執行狀態的發佈者。
    public private(set) lazy var restartDeviceStatePublisher: AnyPublisher<Bool?, Never> = {
        self.coreSDKService.restartDeviceStateSubject.eraseToAnyPublisher()
    }()
    
    /**
     讀取部件參數的方法。
     
     - parameter name: 部件參數的名稱。
     - Throws: 未定義的部件名稱，將會導致錯誤的拋出。
     - Throws: 來自 CoreSDK 判定的錯誤，應該是肇因於參數的錯誤。
     */
    public func readParameter(name: ParameterData.Name) throws {
        let repository: ParameterDataRepository = self.coreSDKService.parameterDataRepository
        let parameterData: ParameterData = try repository.findParameterData(name: name)
        try self.coreSDKService.read(parameter: parameterData)
    }
    
    /**
     寫入部件參數的方法。
     
     - parameter name: 部件參數的名稱。
     - Returns: 未定義的部件名稱，將會導致錯誤的拋出。
     - Throws: 參數的型別或數值等各分面可能導致的錯誤。
     */
    public func writeParameter(name: ParameterData.Name, value: Any) throws {
        let repository: ParameterDataRepository = self.coreSDKService.parameterDataRepository
        var parameterData: ParameterData = try repository.findParameterData(name: name)
        parameterData.value = value
        try self.coreSDKService.write(parameter: parameterData)
    }
    
    /**
     重啟部件的方法。
     
     - parameter partType: 部件類別。
     - Throws: 來自 CoreSDK 判定的錯誤，應該是肇因於參數的錯誤。
     */
    public func restartDevice(partType: CommunicationPartType) throws {
        try self.coreSDKService.restartDevice(partType: partType)
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
            .throttle(for: .milliseconds(700), scheduler: RunLoop.main, latest: true)
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
    
    /// 更新特徵時的發佈者。
    public private(set) lazy var didUpdateValueForCharacteristicsPublisher: AnyPublisher<BluetoothCharacteristic?, Never> = {
        self.coreBluetoothService.didUpdateValueForCharacteristicsSubject.eraseToAnyPublisher()
    }()
    
    /// 寫入特徵時的發佈者。
    public private(set) lazy var didWriteValueForCharacteristicsPublisher: AnyPublisher<BluetoothCharacteristic?, Never> = {
        self.coreBluetoothService.didWriteValueForCharacteristicsSubject.eraseToAnyPublisher()
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
        self.coreSDKService.startReadWriteChannel()
    }
    
    /**
     對於藍牙裝置斷開連結。
     
     - parameter bluetoothPeripheral: 欲斷開連結的目標藍牙裝置。
     */
    public func disconnect(_ bluetoothPeripheral: BluetoothPeripheral) {
        self.connectedPeripheral.reset()
        self.coreBluetoothService.disconnect(peripheral: bluetoothPeripheral)
        self.coreSDKService.stopReadWriteChannel()
        self.coreSDKService.deviceInfoSubject.send(nil)
    }
    
    /**
     讀取藍牙裝置的 RSSI 值。
     
     - Precondition: 對於當前連結的藍牙裝置，讀取 RSSI 值。
     - Precondition: 此方法，呼叫一次，僅會得到一次回傳值，並非連續性的監聽。
     */
    public func readRSSI() {
        self.connectedPeripheral.currentPeripheral.value?.device.readRSSI()
    }
}
