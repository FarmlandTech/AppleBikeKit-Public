//
//  CoreSdkService.swift
//  DST
//
//  Created by abe chen on 2022/11/1.
//

import Foundation
import Combine

import CoreSDK

public final class CoreSDKService: NSObject {
    
    // MARK: 委派
    
    /// CoreSDKService 操作 CoreSDK 時，需透過委派來取得回調的資訊。
    private static weak var dataSource: CoreSDKDataSource?
    
    // MARK: 回調
    
    /// 刷新腳踏車資訊時的回調。
    private let updateDeviceInfoEvent: UpdateDeviceInfoEvent = {
        CoreSDKService.dataSource?.updateDeviceInfo(deviceInfo: $0.FL)
    }
    
    /// 讀取參數時的回調。
    private let readParameterEvent: ReadParameterEvent = {
        guard let pointer: UnsafeMutablePointer<UInt8> = $2 else { return }
        CoreSDKService.dataSource?.readParameter(rawData: .init(targetDevice: $1,
                                                                bank: $5,
                                                                address: $3,
                                                                length: $4,
                                                                returnState: $0,
                                                                pointer: pointer))
    }
    
    /// 寫入參數時的回調。
    private let writeParameterEvent: WriteParameterEvent = {
        CoreSDKService.dataSource?.writeParameter(state: $0 == 0)
    }
    
    /// 重啟部件時的回調。
    private let restartPartEvent: RestartPartEvent = {
        CoreSDKService.dataSource?.restartPart(state: $0 == 0)
    }
    
    /// 重置部件參數時的回調。
    private let resetPartParameterEvent: ResetPartParameterEvent = {
        CoreSDKService.dataSource?.resetPartParameter(state: $0 == 0)
    }
    
    /// 校正電控時間時的回調。
    private let updateSystemTimeEvent: UpdateSystemTimeEvent = {
        CoreSDKService.dataSource?.updateSystemTime(state: $0 == 0)
    }
    
    private let lightControlEvent: LightControlEvent = {
        CoreSDKService.dataSource?.lightControl(state: $0 == 0)
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
    public private(set) lazy var deviceInfoSubject: CurrentValueSubject<FL_Info_st?, Never> = {
        .init(nil)
    }()
    
    /// 讀取參數的數據流。
    public private(set) lazy var readingRawDataSubject: CurrentValueSubject<RawData?, Never> = {
        .init(nil)
    }()
    
    /// 寫入參數時，命令執行狀態的數據流。
    public private(set) lazy var writingParameterStateSubject: CurrentValueSubject<Bool?, Never> = {
        .init(nil)
    }()
    
    /// 重啟部件時，命令執行狀態的數據流。
    public private(set) lazy var restartingPartStateSubject: CurrentValueSubject<Bool?, Never> = {
        .init(nil)
    }()
    
    /// 重置部件參數時，命令執行狀態的數據流。
    public private(set) lazy var resetingPartParameterStateSubject: CurrentValueSubject<Bool?, Never> = {
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
    
    public var sdkVersion: String {
        var version: [UInt8] = Mirror(reflecting: self.coreSDKInst.Version)
            .children
            .map({ $0.value as! UInt8 })
        version.removeAll(where: { $0 == 0 })
        return String(describing: String(bytes: version, encoding: .utf8))
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
}

// MARK: - CoreSDK Protocol

extension CoreSDKService: CoreSDKDataSource {
    
    func updateDeviceInfo(deviceInfo: FL_Info_st) {
        self.deviceInfoSubject.send(deviceInfo)
    }
    
    func readParameter(rawData: RawData) {
        self.readingRawDataSubject.send(rawData)
    }
    
    func writeParameter(state: Bool) {
        self.writingParameterStateSubject.send(state)
    }
    
    func restartPart(state: Bool) {
        self.restartingPartStateSubject.send(state)
    }
    
    func resetPartParameter(state: Bool) {
        self.resetingPartParameterStateSubject.send(state)
    }
    
    func updateSystemTime(state: Bool) {
        self.updatingSystemTimeStateSubject.send(state)
    }
    
    func lightControl(state: Bool) {
        self.lightControlStateSubject.send(state)
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
        /// 重置部件參數失敗。
        case resetPartParameterFail(CommunicationPartType, Int)
        /// 校正電控時間失敗。
        case updateSystemTimeFail
        /// 控制車燈開關失敗。
        case lightControlFail
        
    }
}

// MARK: - 取得 CoreSDK 回調的委派協定

/// CoreSDKService 操作 CoreSDK 時，需透過委派來取得回調的資訊。
private protocol CoreSDKDataSource: AnyObject {
    
    /// 刷新腳踏車資訊時，回調的資訊。
    func updateDeviceInfo(deviceInfo: FL_Info_st)
    /// 讀取參數時，回調的資訊。
    func readParameter(rawData: RawData)
    /// 寫入參數時，回調的資訊。
    func writeParameter(state: Bool)
    /// 重啟部件時，回調的資訊。
    func restartPart(state: Bool)
    /// 重置部件參數時，回調的資訊。
    func resetPartParameter(state: Bool)
    /// 校正電控時間時，回調的資訊。
    func updateSystemTime(state: Bool)
    /// 控制車燈開關，回調的資訊。
    func lightControl(state: Bool)
}

// MARK: - 取得 CoreSDK 回調的方法別名

extension CoreSDKService {
    
    /// 刷新腳踏車資訊時，回調的別名。
    private typealias UpdateDeviceInfoEvent = @convention(c) (DeviceInformation_T) -> Void
    /// 讀取參數時，回調的別名。
    private typealias ReadParameterEvent = @convention(c) (Int32, DeviceType_enum, Optional<UnsafeMutablePointer<UInt8>>, UInt16, UInt16, UInt8) -> Void
    /// 寫入參數時，回調的別名。
    private typealias WriteParameterEvent = @convention(c) (Int32) -> Void
    /// 重啟部件時，回調的別名。
    private typealias RestartPartEvent = @convention(c) (Int32) -> Void
    /// 重置部件參數時，回調的別名。
    private typealias ResetPartParameterEvent = @convention(c) (Int32) -> Void
    /// 校正電控時間時，回調的別名。
    private typealias UpdateSystemTimeEvent = @convention(c) (Int32) -> Void
    /// 控制車燈開關，回調的別名。
    private typealias LightControlEvent = @convention(c) (Int32) -> Void
}
