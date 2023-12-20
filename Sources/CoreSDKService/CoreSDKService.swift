//
//  CoreSdkService.swift
//  DST
//
//  Created by abe chen on 2022/11/1.
//

import Foundation
import Combine

import CoreSDKSourceCode

public final class CoreSDKService: NSObject {
    
    // MARK: 委派
    
    /// CoreSDKService 操作 CoreSDK 時，需透過委派來取得回調的資訊。
    private static weak var dataSource: CoreSDKDataSource?
    
    // MARK: 回調
    
    /// 刷新腳踏車資訊時，回調的別名。
    private typealias UpdateDeviceInfoEvent = @convention(c) (DeviceInformation_T) -> Void
    /// 刷新腳踏車資訊時的回調。
    private let updateDeviceInfoEvent: UpdateDeviceInfoEvent = {
        CoreSDKService.dataSource?.updateDeviceInfo(deviceInfo: $0.FL)
    }
    
    /// 讀取參數時的回調。
    private let readParameterEvent: fpCallback_ReadParameters = {
        guard let pointer: UnsafeMutablePointer<UInt8> = $2 else { return }
        CoreSDKService.dataSource?.readParameter(rawData: .init(device: $1,
                                                                bank: $5,
                                                                address: $3,
                                                                length: $4,
                                                                state: $0 == 0,
                                                                pointer: pointer))
    }
    
    /// 寫入參數時的回調。
    private let writeParameterEvent: fpCallback_WriteParameters = {
        CoreSDKService.dataSource?.writeParameter(rawData: .init(device: $1,
                                                                 bank: $4,
                                                                 address: $2,
                                                                 length: $3,
                                                                 state: $0 == 0))
    }
    
    /// 重啟部件時的回調。
    private let restartPartEvent: fpCallback_RestartDevice = {
        CoreSDKService.dataSource?.restartPart(state: $0 == 0)
    }
    
    /// 重置里程參數的回調。
    private let resetTripInfoEvent: fpCallback_ClearTripInfo = {
        CoreSDKService.dataSource?.resetTripInfo(state: $0 == 0)
    }
    
    /// 重置部件參數時的回調。
    private let resetPartParameterEvent: fpCallback_ResetParameters = {
        CoreSDKService.dataSource?.resetPartParameter(rawData: .init(device: $1,
                                                                     bank: $2,
                                                                     state: $0 == 0))
    }
    
    /// 校正電控時間時的回調。
    private let updateSystemTimeEvent: fpCallback_ConfigSysTime = {
        CoreSDKService.dataSource?.updateSystemTime(state: $0 == 0)
    }
    
    /// 控制車燈開關時的回調。
    private let lightControlEvent: fpCallback_LightControl = {
        CoreSDKService.dataSource?.lightControl(state: $0 == 0)
    }
    
    /// 更新韌體時的回調。(進度及資訊)
    private let upgradeFirmwareProgress: UpgradeStateMsg_p = {
        CoreSDKService.dataSource?.upgradeFirmware(rawData: .init(pointer: $0, progress: $1))
    }
    
    /// 更新韌體時的回調。(執行結果)
    private let upgradeFirmwareEvent: fpCallback_UpgradeFirmware = {
        CoreSDKService.dataSource?.upgradeFirmware(code: $0)
    }
    
    /// 取得電子鎖狀態時的回調。
    private let getELockEvent: fpCallback_GetELock_DEV = {
        CoreSDKService.dataSource?.getELock(state: $1)
    }
    
    // MARK: 數據流
    
    // TODO: 找時間改以 Result Type 來改寫傳入值，以免數據為空值時，造成訂閱的終結。
    
    public private(set) lazy var commandPacketSubject: CurrentValueSubject<[UInt8], Never> = {
        .init(.init())
    }()
    
    public private(set) lazy var dataPacketSubject: CurrentValueSubject<[UInt8], Never> = {
        .init(.init())
    }()
    
    /// 新腳踏車資訊的數據流。
    public private(set) lazy var deviceInfoSubject: CurrentValueSubject<(deviceInfo: FL_Info_st?, timestamp: Date), Never> = {
        let value: (FL_Info_st?, Date) = (nil, .init())
        return .init(value)
    }()
    
    /// 讀取參數的數據流。
    public private(set) lazy var readingRawDataSubject: CurrentValueSubject<ReadingRawData?, Never> = {
        .init(nil)
    }()
    
    /// 寫入參數時，命令執行狀態的數據流。
    public private(set) lazy var writingParameterStateSubject: CurrentValueSubject<WritingRawData?, Never> = {
        .init(nil)
    }()
    
    /// 重啟部件時，命令執行狀態的數據流。
    public private(set) lazy var restartingPartStateSubject: CurrentValueSubject<Bool?, Never> = {
        .init(nil)
    }()
    
    /// 重置里程參數時，命令執行狀態的數據流。
    public private(set) lazy var resetTripInfoSubject: CurrentValueSubject<Bool?, Never> = {
        .init(nil)
    }()
    
    /// 重置部件參數時，命令執行狀態的數據流。
    public private(set) lazy var resetingPartParameterStateSubject: CurrentValueSubject<ResetingRawData?, Never> = {
        .init(nil)
    }()
    
    /// 校正電控時間時，命令執行狀態的數據流。
    public private(set) lazy var updatingSystemTimeStateSubject: CurrentValueSubject<Bool?, Never> = {
        .init(nil)
    }()
    
    /// 控制車燈開關時，命令執行狀態的數據流。
    public private(set) lazy var lightControlStateSubject: CurrentValueSubject<Bool?, Never> = {
        .init(nil)
    }()
    
    /// 更新韌體(進度及資訊)時，命令執行狀態的數據流。
    public private(set) lazy var upgradeFirmwareProgressSubject: CurrentValueSubject<UpgradingRawData?, Never> = {
        .init(nil)
    }()
    
    /// 更新韌體(執行結果)時，命令執行狀態的數據流。
    public private(set) lazy var upgradeFirmwareStateSubject: CurrentValueSubject<Int32?, Never> = {
        .init(nil)
    }()
    
    /// 取得電子鎖狀態時，命令執行狀態的數據流。
    public private(set) lazy var getElockStateSubject: CurrentValueSubject<ELockStates, Never> = {
        .init(ELOCK_STATES_UNKNOW)
    }()
    
    
    public var sdkVersion: String? {
        var version: [UInt8] = Mirror(reflecting: self.coreSDKInst.Version)
            .children
            .map({ $0.value as! UInt8 })
        version.removeAll(where: { $0 == 0 })
        return String(bytes: version, encoding: .utf8)
    }
    
    private var coreSDKInst = CoreSDKInst_T()
    
    private var timerSubscription: AnyCancellable?
    
    private let outputDataTimer = Timer.publish(every: 0.01, tolerance: 0.5, on: .main, in: .common).autoconnect()
    
    private static var writingData: [UInt8] = .init()
    
    // 產生原始陣列建議 255 長度，丟給 bleSDK 可接受最大長度為 244 (遵從 hmi ble portocol)
    // Write w response
    lazy private var commandPacketOutData: [UInt8] = {
        .init(repeating: 0x00, count: 244)
    }()
    
    lazy private var commandPacketOutDataLeng: UInt32 = {
        255
    }()
    
    // Write w/o response
    lazy private var dataPacketOutData: [UInt8] = {
        .init(repeating: 0x00, count: 244)
    }()
    
    lazy private var dataPacketOutDataLeng: UInt32 = {
        255
    }()
    
    // 處理 Notify 吐回的資料
    public func commandPacketIn(dataPacket: [UInt8]) {
        var data: [UInt8] = dataPacket
        _ = coreSDKInst.Method.BLECommandPacket_IN(&data, UInt32(dataPacket.count))
    }
    
    // 停止讀寫通道，不使用就直接 invalidate timer
    public func stopReadWriteChannel() {
        self.timerSubscription?.cancel()
        self.timerSubscription = nil
        self.outputDataTimer.upstream.connect().cancel()
    }
    
    // 開啟讀寫通道，讀寫參數或 DFU 時要先開啟
    public func startReadWriteChannel() {
        self.stopReadWriteChannel()
        self.timerSubscription = self.outputDataTimer.sink(receiveValue: { [weak self] date in
            guard let self: CoreSDKService else { return }
            
            // part 參數讀寫通道
            let commandPacketOutResult = self.coreSDKInst.Method.BLECommandPacket_OUT(&self.commandPacketOutData, &self.commandPacketOutDataLeng)
            
            // 接收 sdk 處理後的 bin 檔 data，主要是更新 fw 會使用到
            let dataPacketOutResult = self.coreSDKInst.Method.BLEDataPacket_OUT(&self.dataPacketOutData, &self.dataPacketOutDataLeng)
            
            if commandPacketOutResult == SDK_RETURN_SUCCESS.rawValue {
                // 要把處理過的原始封包丟給 BleSDK 去傳給 Hmi
                let length: Int = .init(self.commandPacketOutDataLeng)
                let bytes: [UInt8] = self.commandPacketOutData.convert2Bytes(length: length)
                self.commandPacketSubject.send(bytes)
            }
            
            if dataPacketOutResult == SDK_RETURN_SUCCESS.rawValue {
                let length: Int = .init(self.dataPacketOutDataLeng)
                let bytes: [UInt8] = self.dataPacketOutData.convert2Bytes(length: length)
                self.commandPacketSubject.send(bytes)
            }
        })
    }
    
    /**
     建構子。
     */
    public override init() {
        super.init()
        print("AppleBikeKit[CoreSdkService]: init")
        Self.dataSource = self
        self.initCoreSDK()
        self.enableSDK()
    }
    
    /**
     解構子。
     */
    deinit {
        print("AppleBikeKit[CoreSdkService]: deinit")
        Self.dataSource = nil
        self.disableSDK()
    }
    
    /**
     初始化 CoreSDK 。
     */
    private func initCoreSDK() {
        print("AppleBikeKit[InitializingCoreSDK]: \(self.sdkVersion)")
        self.coreSDKInst.InfoUpdateEvent = self.updateDeviceInfoEvent
        FarmLandCoreSDK_Init(&self.coreSDKInst)
    }
    
    /**
     啟用 CoreSDK 。
     */
    private func enableSDK() {
        // TODO: 找時間了解一下回傳值，如果代表成功或失敗，則可試著拋出錯誤狀態。
        _ = self.coreSDKInst.Enable()
    }
    
    /**
     停用 CoreSDK 。
     */
    private func disableSDK() {
        // TODO: 找時間了解一下回傳值，如果代表成功或失敗，則可試著拋出錯誤狀態。
        _ = self.coreSDKInst.Disable()
    }
    
    /**
     讀取參數。
     
     - parameter parameter: 欲讀取的參數物件。
     - Throws: CoreSDK 執行失敗。
     */
    public func read(parameter: ParameterData) throws {
        let isCoreSDKCompleteTask: Int32 = self.coreSDKInst.DelegateMethod.ReadParameters(SDK_ROUTER_BLE, parameter.partType.coreType, parameter.address, parameter.length, parameter.bank, self.readParameterEvent)
        guard isCoreSDKCompleteTask == 0 else {
            throw CoreSDKService.Error.readParameterFail(parameter)
        }
    }
    
    // TODO: 寫入參數的實作，改寫為 ParameterData 的擴展。
    /**
     寫入參數。
     
     - parameter parameter: 欲寫入的參數物件。
     - Throws: CoreSDK 執行失敗。
     */
    public func write(parameter: ParameterData) throws {
        if let _ = parameter.type as? String.Type {
            guard let value: Any = parameter.value else {
                throw Self.Error.writeParameterWithNoValue
            }
            guard let parameterValue: String = value as? String else {
                throw Self.Error.writeParameterWithWrongType
            }
            
            Self.writingData = .init(repeating: 0, count: .init(parameter.length))
            for (index, char) in parameterValue.utf8.enumerated() {
                guard index < Self.writingData.count else {
                    throw Self.Error.writeTextOutOfRange
                }
                Self.writingData[index] = char
            }
            var isCoreSDKCompleteTask: Int32?
            withUnsafePointer(to: &Self.writingData) { pointer in
                isCoreSDKCompleteTask = self.coreSDKInst.DelegateMethod.WriteParameters(SDK_ROUTER_BLE, parameter.partType.coreType, parameter.address, parameter.length, parameter.bank, pointer.pointee, self.writeParameterEvent)
            }
            guard let isCoreSDKCompleteTask: Int32, isCoreSDKCompleteTask == 0 else {
                throw Self.Error.writeParameterFail(parameter)
            }
        } else if let _ = parameter.type as? Int.Type {
            guard let value: Any = parameter.value else {
                throw Self.Error.writeParameterWithNoValue
            }
            guard let parameterValue: Int = value as? Int else {
                throw Self.Error.writeParameterWithWrongType
            }
            
            let count = 2
            let stride = MemoryLayout<Int32>.stride
            let alignment = MemoryLayout<Int>.alignment
            let byteCount = stride * count
            
            let unsafeMutableRawPointer = UnsafeMutableRawPointer.allocate(byteCount: byteCount, alignment: alignment)
            unsafeMutableRawPointer.storeBytes(of: parameterValue, as: Int.self)
            
            let isCoreSDKCompleteTask: Int32 = self.coreSDKInst.DelegateMethod.WriteParameters(SDK_ROUTER_BLE, parameter.partType.coreType, parameter.address, parameter.length, parameter.bank, unsafeMutableRawPointer, self.writeParameterEvent)
            guard isCoreSDKCompleteTask == 0 else {
                throw Self.Error.writeParameterFail(parameter)
            }
        } else {
            throw Self.Error.writeParameterWithUnexpectedType
        }
    }
    
    /**
     重啟部件。
     */
    public func restartPart(_ part: CommunicationPartType) throws {
        let isCoreSDKCompleteTask: Int32 = self.coreSDKInst.DelegateMethod.RestartDevice(SDK_ROUTER_BLE, part.coreType, self.restartPartEvent)
        guard isCoreSDKCompleteTask == 0 else {
            throw Self.Error.restartPartFail(part)
        }
    }
    
    /**
     重置里程參數。
     */
    public func resetTripInfo() throws {
        let isCoreSDKCompleteTask: Int32 = self.coreSDKInst.DelegateMethod.ClearTripInfo(SDK_ROUTER_BLE, self.resetTripInfoEvent)
        guard isCoreSDKCompleteTask == 0 else {
            throw Self.Error.resetTripInfoFail
        }
    }
    
    /**
     重置部件參數。
     */
    public func resetPartParameter(part: CommunicationPartType, bank: Int) throws {
        let isCoreSDKCompleteTask: Int32 = self.coreSDKInst.DelegateMethod.ResetParameters(SDK_ROUTER_BLE, part.coreType, UInt8(bank), self.resetPartParameterEvent)
        guard isCoreSDKCompleteTask == 0 else {
            throw Self.Error.resetPartParameterFail(part, bank)
        }
    }
    
    /**
     校正電控時間。
     */
    public func updateSystemTime() throws {
        let time: UInt64 = .init(Date().timeIntervalSince1970)
        let isCoreSDKCompleteTask: Int32 = self.coreSDKInst.DelegateMethod.ConfigSysTime(SDK_ROUTER_BLE, SDK_FL_MAIN_BATT, time, self.updateSystemTimeEvent)
        guard isCoreSDKCompleteTask == 0 else {
            throw Self.Error.updateSystemTimeFail
        }
    }
    
    /**
     控制車燈開關。
     
     - parameter part: 前燈或後燈。
     - parameter isOn: 開或關。
     - Throws: CoreSDK 執行失敗。
     */
    public func lightControl(part: light_control_parts = LIGHT_CONTROL_FRONT, isOn: Bool) throws {
        let isCoreSDKCompleteTask: Int32 =  self.coreSDKInst.DelegateMethod.LightControl(SDK_ROUTER_BLE, part, isOn, self.lightControlEvent)
        guard isCoreSDKCompleteTask == 0 else {
            throw Self.Error.lightControlFail
        }
    }
    
    /**
     更新部件韌體。
     
     - parameter part: 部件。
     - parameter data: 韌體。
     - Throws: CoreSDK 執行失敗。
     */
    public func upgradeFirmware(part: CommunicationPartType, data: Data) throws {
        let midPointer: UnsafeMutablePointer<UInt8> = .allocate(capacity: 1)
        midPointer.initialize(to: 0)
        
        var dataPointer: UnsafeMutablePointer<UInt8>?
        data.withUnsafeBytes { (rawBufferPointer: UnsafeRawBufferPointer) in
            dataPointer = .allocate(capacity: data.count)
            dataPointer?.initialize(from: rawBufferPointer.baseAddress!.assumingMemoryBound(to: UInt8.self), count: data.count)
        }
        
        print(part.coreType, data, data.count)
        
        let isCoreSDKCompleteTask: Int32 =  self.coreSDKInst.DelegateMethod.UpgradeFirmware(SDK_ROUTER_BLE, part.coreType, midPointer, dataPointer, UInt32(data.count), self.upgradeFirmwareProgress, self.upgradeFirmwareEvent)
        guard isCoreSDKCompleteTask == 0 else {
            throw Self.Error.upgradeFirmwareFail(part)
        }
        
        midPointer.deallocate()
        dataPointer?.deallocate()
    }
    
    /**
     取得電子鎖狀態。
     
     - Throws: CoreSDK 執行失敗。
     */
    public func getELock() throws {
        let isCoreSDKCompleteTask: Int32 =  self.coreSDKInst.DelegateMethod.GetELock_DEV(SDK_ROUTER_BLE, self.getELockEvent)
        guard isCoreSDKCompleteTask == 0 else {
            throw Self.Error.getELockFail
        }
    }
}

// MARK: - CoreSDK Protocol

extension CoreSDKService: CoreSDKDataSource {
    
    func updateDeviceInfo(deviceInfo: FL_Info_st) {
        let value: (FL_Info_st, Date) = (deviceInfo, .init())
        self.deviceInfoSubject.send(value)
    }
    
    func readParameter(rawData: ReadingRawData) {
        self.readingRawDataSubject.send(rawData)
    }
    
    func writeParameter(rawData: WritingRawData) {
//        self.writingParameterStateSubject.send(rawData)
    }
    
    func restartPart(state: Bool) {
        self.restartingPartStateSubject.send(state)
    }
    
    func resetTripInfo(state: Bool) {
        self.resetTripInfoSubject.send(state)
    }

    func resetPartParameter(rawData: ResetingRawData) {
        self.resetingPartParameterStateSubject.send(rawData)
    }
    
    func updateSystemTime(state: Bool) {
        self.updatingSystemTimeStateSubject.send(state)
    }
    
    func lightControl(state: Bool) {
        self.lightControlStateSubject.send(state)
    }
    
    func upgradeFirmware(rawData: UpgradingRawData) {
        self.upgradeFirmwareProgressSubject.send(rawData)
    }
    
    func upgradeFirmware(code: Int32) {
        self.upgradeFirmwareStateSubject.send(code)
    }
    
    func getELock(state: ELockStates) {
        self.getElockStateSubject.send(state)
    }
}

// MARK: - 操作 CoreSDK 時所遭遇的錯誤

extension CoreSDKService {
    
    /// CoreSDKService 操作 CoreSDK 時所遭遇的錯誤。
    public enum Error: Swift.Error {
        /// 讀取參數失敗。
        case readParameterFail(ParameterData)
        /// 寫入參數時，遭遇到未定義的解析型別。
        case writeParameterWithUnexpectedType
        /// 寫入參數時，欲寫入的內容為空。
        case writeParameterWithNoValue
        /// 寫入參數時，欲寫入的內容與定義的型別不匹配。
        case writeParameterWithWrongType
        /// 寫入參數時，欲寫入的字串，位元長度錯誤。
        case writeTextOutOfRange
        /// 寫入參數失敗。
        case writeParameterFail(ParameterData)
        /// 重啟部件失敗。
        case restartPartFail(CommunicationPartType)
        /// 重置里程參數失敗。
        case resetTripInfoFail
        /// 重置部件參數失敗。
        case resetPartParameterFail(CommunicationPartType, Int)
        /// 校正電控時間失敗。
        case updateSystemTimeFail
        /// 控制車燈開關失敗。
        case lightControlFail
        /// 更新韌體失敗。
        case upgradeFirmwareFail(CommunicationPartType)
        /// 取得電子鎖狀態失敗。
        case getELockFail
    }
}

// MARK: - 取得 CoreSDK 回調的委派協定

/// CoreSDKService 操作 CoreSDK 時，需透過委派來取得回調的資訊。
private protocol CoreSDKDataSource: AnyObject {
    
    /// 刷新腳踏車資訊時，回調的資訊。
    func updateDeviceInfo(deviceInfo: FL_Info_st)
    /// 讀取參數時，回調的資訊。
    func readParameter(rawData: ReadingRawData)
    /// 寫入參數時，回調的資訊。
    func writeParameter(rawData: WritingRawData)
    /// 重啟部件時，回調的資訊。
    func restartPart(state: Bool)
    /// 重置里程參數時，回調的資訊。
    func resetTripInfo(state: Bool)
    /// 重置部件參數時，回調的資訊。
    func resetPartParameter(rawData: ResetingRawData)
    /// 校正電控時間時，回調的資訊。
    func updateSystemTime(state: Bool)
    /// 控制車燈開關，回調的資訊。
    func lightControl(state: Bool)
    /// 更新韌體(進度及資訊)，回調的資訊。
    func upgradeFirmware(rawData: UpgradingRawData)
    /// 更新韌體(執行結果)，回調的資訊。
    func upgradeFirmware(code: Int32)
    /// 取得電子鎖狀態。
    func getELock(state: ELockStates)
}
