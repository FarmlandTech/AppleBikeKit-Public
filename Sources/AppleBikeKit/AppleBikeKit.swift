//
//  AppleBikeKit.swift
//  
//
//  Created by Yves Tsai on 2023/3/28.
//

import Foundation
import Combine
import CoreBluetooth

import CoreSDKSourceCode
import CoreSDKService
import CoreBLEServiceSourceCode
import AppleBikeKitSourceCode

/// 藍牙連線統一的對外接口，整合 CoreSDK 與 CoreBLEService 的調用。
open class AppleBikeKit: BaseAppleBikeKit {
    
    /// 單例。
    public static let shared: AppleBikeKit = .init()
    
    /// 當前連線裝置的實例緩存。
    public private(set) lazy var connectedPeripheral: ConnectedPeripheral = {
        .init()
    }()
    
    // MARK: - CoreSDKService
    
    /// 操作 CoreSDK 的物件實例。
    private let coreSDKService: CoreSDKService = .init()
    
    /// CoreSDK 版本編號。
    public var sdkVersion: String? {
        self.coreSDKService.sdkVersion
    }
    
    /// 腳踏車裝置資訊。(最後一次)
    public var info: (deviceInfo: FL_Info_st?, timestamp: Date) {
        self.coreSDKService.deviceInfoSubject.value
    }
    
    /// 用於 CoreSDK 的參數倉庫，包括定義與緩存，也實作部分的邏輯。
    public private(set) lazy var parameterDataRepository: ParameterDataRepository = {
        .init()
    }()
    
    @available(*, deprecated, message: "该方法已被弃用，请改用 deviceInfoPublisher(throttle:) 方法。")
    /// 腳踏車裝置資訊的發佈者。
    public private(set) lazy var deviceInfoPublisher: AnyPublisher<(deviceInfo: FL_Info_st?, timestamp: Date), Never> = {
        self.coreSDKService.deviceInfoSubject
            .throttle(for: .milliseconds(700), scheduler: RunLoop.main, latest: true)
            .eraseToAnyPublisher()
    }()
    
    /// 腳踏車裝置資訊的發佈者。
    public func deviceInfoPublisher(throttle milliseconds: Int = 0) -> AnyPublisher<(deviceInfo: FL_Info_st?, timestamp: Date), Never> {
        if milliseconds > 0 {
            return self.coreSDKService.deviceInfoSubject
                .throttle(for: .milliseconds(milliseconds), scheduler: RunLoop.main, latest: true)
                .eraseToAnyPublisher()
        } else {
            return self.coreSDKService.deviceInfoSubject
                .eraseToAnyPublisher()
        }
    }
    
    /// 讀取參數時，電控回傳數據的發佈者。
    private let parameterDataSubject: PassthroughSubject<ParameterData, Swift.Error> = .init()
    
    /// 腳踏車裝置讀取來的參數的發佈者。
    public private(set) lazy var parameterDataPubisher: AnyPublisher<ParameterData, Swift.Error> = {
        self.parameterDataSubject.eraseToAnyPublisher()
    }()
    
    /// 寫入參數時，執行狀態的發佈者。
    public private(set) lazy var writingParameterStatePublisher: AnyPublisher<WritingRawData?, Never> = {
        self.coreSDKService.writingParameterStateSubject.eraseToAnyPublisher()
    }()
    
    /// 重啟部件時，執行狀態的發佈者。
    public private(set) lazy var restartDeviceStatePublisher: AnyPublisher<Bool?, Never> = {
        self.coreSDKService.restartingPartStateSubject.eraseToAnyPublisher()
    }()
    
    /// 重置里程參數時，執行狀態的發佈者。
    public private(set) lazy var resetTripInfoStatePublisher: AnyPublisher<Bool, Never> = {
        self.coreSDKService.resetTripInfoSubject.compactMap({ $0 }).eraseToAnyPublisher()
    }()
    
    /// 重置部件參數時，執行狀態的發佈者。
    public private(set) lazy var resetParameterStatePublisher: AnyPublisher<ResetingRawData?, Never> = {
        self.coreSDKService.resetingPartParameterStateSubject.eraseToAnyPublisher()
    }()
    
    /// 校正電控時間時，執行狀態的發佈者。
    public private(set) lazy var updatingSystemTimeStatePublisher: AnyPublisher<Bool?, Never> = {
        self.coreSDKService.updatingSystemTimeStateSubject.eraseToAnyPublisher()
    }()
    
    /// 控制車燈開關時，執行狀態的發佈者。
    public private(set) lazy var lightControlStatePublisher: AnyPublisher<Bool?, Never> = {
        self.coreSDKService.lightControlStateSubject.eraseToAnyPublisher()
    }()
    
    
    /// 更新韌體(進度及資訊)時，執行狀態的發佈者。
    public private(set) lazy var upgradeFirmwareProgressPublisher: AnyPublisher<UpgradingRawData?, Never> = {
        self.coreSDKService.upgradeFirmwareProgressSubject.eraseToAnyPublisher()
    }()

    /// 更新韌體(執行結果)時，執行狀態的發佈者。
    public private(set) lazy var upgradeFirmwareStatePublisher: AnyPublisher<Int32?, Never> = {
        self.coreSDKService.upgradeFirmwareStateSubject.eraseToAnyPublisher()
    }()
    
    /// 取得電子鎖狀態時，執行狀態的發佈者。
    public private(set) lazy var getELockStatePublisher: AnyPublisher<ELockStates, Never> = {
        self.coreSDKService.getElockStateSubject
            .removeDuplicates()
            .eraseToAnyPublisher()
    }()
    
    override open func subscribeCoreSDKServiceSubjects() {
        super.subscribeCoreSDKServiceSubjects()
        
        // 監聽參數寫入的事件處理。
        self.coreSDKService.commandPacketSubject
            .sink(receiveValue: { output in
                guard let characteristic: CBCharacteristic = self.connectedPeripheral.writeCharacteristicSubject.value else { return }
                self.connectedPeripheral.currentPeripheralSubject.value?.writeValue(.init(output), for: characteristic)
            })
            .store(in: &self.subscriptions)
        
        // 監聽更新韌體的事件處理。
        self.coreSDKService.dataPacketSubject
            .sink(receiveValue: { output in
                guard let characteristic: CBCharacteristic = self.connectedPeripheral.writeWithoutResponseCharacteristicSubject.value else { return }
                self.connectedPeripheral.currentPeripheralSubject.value?.writeValue(.init(output), for: characteristic)
            })
            .store(in: &self.subscriptions)
        
        self.coreSDKService.deviceInfoSubject
            .sink(receiveValue: { _ in
                
            })
            .store(in: &self.subscriptions)
        
        // 監聽參數讀取的事件處理。
        self.coreSDKService.readingRawDataSubject
            .compactMap({ $0 })
            .sink(receiveValue: { rawData in
                func setParameterValue(_ parameterData: ParameterData) {
                    guard let index: Int = self.parameterDataRepository.parameters.firstIndex(where: { $0.name == parameterData.name }) else { return }
                    DispatchQueue.main.async {
                        self.parameterDataRepository.parameters[index].subject.send(parameterData.value)
                    }
                    self.parameterDataRepository.parameters[index].value = parameterData.value
                }
                
                do {
                    let parameterData: ParameterData = try self.parameterDataRepository.findParameterData(type: rawData.device,
                                                                                                          bank: rawData.bank,
                                                                                                          address: rawData.address,
                                                                                                          length: rawData.length)
                    if self.parameterDataRepository.integratedParameters.contains(where: { $0.name == parameterData.name }) {
                        let parameterDataList: [ParameterData] = try parameterData.dividIntoMultiParameters(rawData: rawData)
                        // 將讀取到的內容，分別存到個別參數內緩存，並透過 subject 傳遞出去。
                        for parameterData in parameterDataList {
                            self.parameterDataSubject.send(parameterData)
                            setParameterValue(parameterData)
                        }
                        // 將讀取到的內容，封裝起來，且透過 subject 傳遞出去。
                        let result: ParameterData = .init(name: parameterData.name,
                                                          partType: parameterData.partType,
                                                          bank: parameterData.bank,
                                                          address: parameterData.address,
                                                          length: parameterData.length,
                                                          type: parameterData.type,
                                                          dividedParameters: parameterDataList)
                        self.parameterDataSubject.send(result)
                    } else {
                        parameterData.value = try rawData.bytes.convert2Value(type: parameterData.type,
                                                                              length: Int(parameterData.length))
                        self.parameterDataSubject.send(parameterData)
                        setParameterValue(parameterData)
                    }
                } catch {
                    self.parameterDataSubject.send(completion: .failure(error))
                }
            })
            .store(in: &self.subscriptions)
        
        self.coreSDKService.writingParameterStateSubject
            .sink(receiveValue: { _ in
                
            })
            .store(in: &self.subscriptions)
        
        self.coreSDKService.restartingPartStateSubject
            .sink(receiveValue: { _ in
                
            })
            .store(in: &self.subscriptions)
        
        self.coreSDKService.resetingPartParameterStateSubject
            .sink(receiveValue: { _ in
                
            })
            .store(in: &self.subscriptions)
        
        self.coreSDKService.updatingSystemTimeStateSubject
            .sink(receiveValue: { _ in
                
            })
            .store(in: &self.subscriptions)
        
        self.coreSDKService.lightControlStateSubject
            .sink(receiveValue: { _ in
                
            })
            .store(in: &self.subscriptions)
        
        self.coreSDKService.getElockStateSubject
            .sink(receiveValue: { _ in
                
            })
            .store(in: &self.subscriptions)
    }
    
    override open func subscribeCoreBLEServiceSubjects() {
        super.subscribeCoreBLEServiceSubjects()
        
        // 監聽特徵，確認連線狀態。
        self.characteristicsPublisher
            .sink(receiveValue: { peripheral in
                // 取得每個服務。
                self.connectedPeripheral.currentPeripheralSubject.value?.device.services?.forEach({ [weak self] service in
                    guard let self: AppleBikeKit else { return }
                    guard let characteristics: [CBCharacteristic] = service.characteristics else { return }
                    // 取得每個服務的所有特徵。
                    characteristics.forEach { [weak self] characteristic in
                        guard let self: AppleBikeKit else { return }
                        guard let type: CoreBluetoothService.CharacteristicWriteType = .init(rawValue: characteristic.uuid.uuidString) else { return }
                        // 判斷特徵型態，並緩存。
                        switch type {
                        case .write:
                            self.connectedPeripheral.writeCharacteristicSubject.value = characteristic
                        case .notify:
                            self.connectedPeripheral.notifyCharacteristicSubject.value = characteristic
                            // 訂閱通知。
                            self.connectedPeripheral.currentPeripheralSubject.value?.device.setNotifyValue(true, for: characteristic)
                        case .writeWithoutResponse:
                            self.connectedPeripheral.writeWithoutResponseCharacteristicSubject.value = characteristic
                        }
                    }
                })
            })
            .store(in: &self.subscriptions)
        
        // 監聽特徵寫入事件，處理廣播參數。
        self.didUpdateValueForCharacteristicsPublisher
            .compactMap({ (result: Result<CBCharacteristic, Swift.Error>?) -> CBCharacteristic? in
                guard let result: Result<CBCharacteristic, Swift.Error>, case .success(let characteristic) = result else {
                    return nil
                }
                return characteristic
            })
            .sink(receiveValue: { [weak self] (characteristic: CBCharacteristic) in
                guard let self: AppleBikeKit else { return }
                guard let value: Data = characteristic.value else { return }
                self.coreSDKService.commandPacketIn(dataPacket: Array(value))
            })
            .store(in: &self.subscriptions)
        
        self.didWriteValueForCharacteristicsPublisher
            .sink(receiveValue: { _ in
                
            })
            .store(in: &self.subscriptions)
        
        self.coreBluetoothService.rssiSubject
            .sink(receiveValue: { _ in
                
            })
            .store(in: &self.subscriptions)
        
        self.coreBluetoothService.stateSubject
            .sink(receiveValue: { _ in
                
            })
            .store(in: &self.subscriptions)
        
        self.coreBluetoothService.scanningSubject
            .sink(receiveValue: { _ in
                
            })
            .store(in: &self.subscriptions)
        
        self.coreBluetoothService.foundDevicesSubject
            .sink(receiveValue: { _ in
                
            })
            .store(in: &self.subscriptions)
        
        self.coreBluetoothService.peripheralSubject
            .sink(receiveValue: { status in
                guard case .didDisconnect = status else { return }
                self.coreBluetoothService.foundDevicesSubject.value = .init()
            })
            .store(in: &self.subscriptions)
    }
    
    override open func doTasks() {
        super.doTasks()
    }
    
    /**
     讀取部件參數的方法。
     
     - parameter name: 部件參數的名稱。
     - Throws: 未定義的部件名稱，將會導致錯誤的拋出。
     - Throws: 來自 CoreSDK 判定的錯誤，應該是肇因於參數的錯誤。
     */
    public func readParameter(name: ParameterData.Name) throws {
        let parameterData: ParameterData = try self.parameterDataRepository.findParameterData(name: name)
        try self.coreSDKService.read(parameter: parameterData)
    }
    
    /**
     寫入部件參數的方法。
     
     - parameter name: 部件參數的名稱。
     - Returns: 未定義的部件名稱，將會導致錯誤的拋出。
     - Throws: 參數的型別或數值等各分面可能導致的錯誤。
     */
    public func writeParameter(name: ParameterData.Name, value: Any) throws {
        let parameterData: ParameterData = try self.parameterDataRepository.findParameterData(name: name)
        parameterData.value = value
        try self.coreSDKService.write(parameter: parameterData)
    }
    
    /**
     重啟部件的方法。
     
     - parameter partType: 部件類別。
     - Throws: 來自 CoreSDK 判定的錯誤，應該是肇因於參數的錯誤。
     */
    public func restartDevice(partType: CommunicationPartType) throws {
        try self.coreSDKService.restartPart(partType)
    }
    
    /**
     重置里程參數的方法。
     
     - Throws: 來自 CoreSDK 判定的錯誤。
     */
    public func resetTripInfo() throws {
        try self.coreSDKService.resetTripInfo()
    }
    
    /**
     取得電子鎖狀態。
     
     - Throws: 來自 CoreSDK 判定的錯誤。
     */
    public func getELock() throws {
        try self.coreSDKService.getELock()
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
            .map({ elements in
                elements.map({ $0.peripheral })
            })
            .map({ peripherals in
                peripherals.filter({
                    $0.deviceName != nil && ($0.deviceName!.hasPrefix("FL") || $0.deviceName!.hasPrefix("Farmland"))
                })
            })
            .throttle(for: .milliseconds(700), scheduler: RunLoop.main, latest: true)
            .eraseToAnyPublisher()
    }()
    
    /// 已連線裝置的發佈者。(包含其連線狀態與斷線狀態)
    public private(set) lazy var peripheralPublisher: AnyPublisher<CoreBluetoothService.PeripheralStatus, Never> = {
        self.coreBluetoothService.peripheralSubject.eraseToAnyPublisher()
    }()
    
    /// 已搜尋到特徵的發佈者。
    public private(set) lazy var characteristicsPublisher: AnyPublisher<CBPeripheral?, Never> = {
        self.coreBluetoothService.characteristicsSubject
            .filter({ $0?.identifier == self.connectedPeripheral.currentPeripheralSubject.value?.device.identifier })
            .eraseToAnyPublisher()
    }()
    
    /// 更新特徵時的發佈者。
    public private(set) lazy var didUpdateValueForCharacteristicsPublisher: AnyPublisher<Result<CBCharacteristic, Swift.Error>?, Never> = {
        self.coreBluetoothService.didUpdateValueForCharacteristicsSubject.eraseToAnyPublisher()
    }()
    
    /// 寫入特徵時的發佈者。
    public private(set) lazy var didWriteValueForCharacteristicsPublisher: AnyPublisher<Result<CBCharacteristic, Swift.Error>?, Never> = {
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
        self.connectedPeripheral.currentPeripheralSubject.value = bluetoothPeripheral
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
        self.coreSDKService.deviceInfoSubject.send((nil, .init()))
    }
    
    /**
     讀取藍牙裝置的 RSSI 值。
     
     - Precondition: 對於當前連結的藍牙裝置，讀取 RSSI 值。
     - Precondition: 此方法，呼叫一次，僅會得到一次回傳值，並非連續性的監聽。
     */
    public func readRSSI() {
        self.connectedPeripheral.currentPeripheralSubject.value?.device.readRSSI()
    }
    
    public func updateSystemTime() throws {
        try self.coreSDKService.updateSystemTime()
    }
    
    /**
     控制車燈開關。
     
     - parameter part: 前燈或後燈。
     - parameter isOn: 開或關。
     - Throws: CoreSDK 執行失敗。
     */
    open func lightControl(part: light_control_parts = LIGHT_CONTROL_FRONT, isOn: Bool) throws {
        try self.coreSDKService.lightControl(part: part, isOn: isOn)
    }
    
    /**
     更新韌體。
     
     - parameter part: 部件。
     - parameter firmware: 韌體。
     - Throws: CoreSDK 執行失敗。
     */
    open func upgradeFirmware(part: CommunicationPartType, firmware: Data) throws {
        try self.coreSDKService.upgradeFirmware(part: part, data: firmware)
    }
    
    /**
     設定助力段數。
     
     - parameter level: 助力段數。
     - Throws: CoreSDK 執行失敗。
     */
    open func setAssistLevel(_ level: UInt8) throws {
        try self.coreSDKService.setAssistLevel(level)
    }
}
