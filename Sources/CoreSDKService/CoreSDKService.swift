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
    
    public enum ScreenLockState {
        case lock
        case unlock(String)
    }
    
    /// 代表 App 的 DataBus 配置，用於識別不同的運行環境或客戶端。
    private var dataBus: DataBus?
    
    /// 代表 App 的 DelegateFunction 配置，用於識別不同的運行環境或客戶端。
    private var delegateFunction: DelegateFunction?
    
    let tenant: Tenant
    
    // MARK: 委派
    
    /// CoreSDKService 操作 CoreSDK 時，需透過委派來取得回調的資訊。
    private static weak var dataSource: CoreSDKDataSource?
    
    // MARK: 回調
    
    /// 刷新腳踏車資訊時，回調的別名。
    private typealias UpdateDeviceInfoEvent = @convention(c) (ProtocolType, DeviceInformation_T) -> Void
    /// 刷新腳踏車資訊時的回調。
    private let updateDeviceInfoEvent: UpdateDeviceInfoEvent = {
        CoreSDKService.dataSource?.updateDeviceInfo(deviceInfo: $1)
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
    private let restartPartEvent: fpCallback_NoParamReturn = {
        CoreSDKService.dataSource?.restartPart(state: $0 == 0)
    }
    
    /// 重置里程參數的回調。
    private let resetTripInfoEvent: fpCallback_NoParamReturn = {
        CoreSDKService.dataSource?.resetTripInfo(state: $0 == 0)
    }
    
    /// 重置部件參數時的回調。
    private let resetPartParameterEvent: fpCallback_ResetParameters = {
        CoreSDKService.dataSource?.resetPartParameter(rawData: .init(device: $1,
                                                                     bank: $2,
                                                                     state: $0 == 0))
    }
    
    /// 校正電控時間時的回調。
    private let updateSystemTimeEvent: fpCallback_NoParamReturn = {
        CoreSDKService.dataSource?.updateSystemTime(state: $0 == 0)
    }
    
    /// 控制車燈開關時的回調。
    private let lightControlEvent: fpCallback_NoParamReturn = {
        CoreSDKService.dataSource?.lightControl(state: $0 == 0)
    }
    
    /// 更新韌體時的回調。(進度及資訊)
    private let upgradeFirmwareProgress: UpgradeStateMsg_p = {
        CoreSDKService.dataSource?.upgradeFirmware(rawData: .init(pointer: $0, progress: $1))
    }
    
    /// 更新韌體時的回調。(執行結果)
    private let upgradeFirmwareEvent: fpCallback_NoParamReturn = {
        CoreSDKService.dataSource?.upgradeFirmware(code: $0)
    }
    
    /// 取得電子鎖狀態時的回調。
    private let getELockEvent: fpCallback_GetELock_DEV = {
        CoreSDKService.dataSource?.getELock(state: $1)
    }
    
    /// 設定電子鎖狀態時的回調。
    private let setELockEvent: fpCallback_NoParamReturn = {
        CoreSDKService.dataSource?.setELock(state: $0 == 0)
    }
    
    /// 設定助力段數時的回調。
    private let setAssistLevelEvent: fpCallback_NoParamReturn = {
        CoreSDKService.dataSource?.setAssistLevel(state: $0 == 0)
    }
    
    /// 重置參數時的回調。
    private let resetDeviceParameterEvent: fpCallback_NoParamReturn = {
        CoreSDKService.dataSource?.resetDeviceParameter(state: $0 == 0)
    }
    
    /// 設定車輛狀態時的回調。
    private let setBikeStatusEvent: fpCallback_NoParamReturn = {
        CoreSDKService.dataSource?.setBikeStatus(state: $0 == 0)
    }
    
    /// 設定車輛為手動診斷狀態時的回調。
    private let setManualTestEvent: fpCallback_NoParamReturn = {
        CoreSDKService.dataSource?.setManualTest(state: $0 == 0)
    }
    
    /// 取得電池資訊時的回調。
    private let readBatteryInfoEvent: fpCallback_NoParamReturn = {
        CoreSDKService.dataSource?.readBatteryInfo(state: $0 == 0)
    }
    
    /// 重置車輛騎乘參數設定時的回調。
    private let resetRideConfigEvent: fpCallback_NoParamReturn = {
        CoreSDKService.dataSource?.resetRideConfig(state: $0 == 0)
    }
    
    /// 重置保養里程紀錄時的回調。
    private let resetMaintenanceMileageEvent: fpCallback_NoParamReturn = {
        CoreSDKService.dataSource?.resetMaintenanceMileage(state: $0 == 0)
    }
    
    private let setHMIAccessControlEvent: fpCallback_SetScreenAccessCtrl = {
        CoreSDKService.dataSource?.setScreenAccessControl(state: $0 == 0, device: $1, action: Int($2), password: "\($3)")
    }
    
    private let resetHMIAccessControlEvent: fpCallback_ResetScreenAccessCtrl = {
        CoreSDKService.dataSource?.resetScreenAccessControl(state: $0 == 0, device: $1)
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
    public private(set) lazy var deviceInfoSubject: CurrentValueSubject<(deviceInfo: DeviceInfo?, timestamp: Date), Never> = {
        let value: (DeviceInfo?, Date) = (nil, .init())
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
    
    /// 設定電子鎖狀態時，命令執行狀態的數據流。
    public private(set) lazy var setELockStateSubject: CurrentValueSubject<Bool?, Never> = {
        .init(nil)
    }()
    
    /// 設定助力段數時，命令執行狀態的數據流。
    public private(set) lazy var setAssistLevelStateSubject: CurrentValueSubject<Bool?, Never> = {
        .init(nil)
    }()
    
    /// 重置參數時，命令執行狀態的數據流。
    public private(set) lazy var resetDeviceParameterStateSubject: CurrentValueSubject<Bool?, Never> = {
        .init(nil)
    }()
    
    ///  設定車輛狀態時，命令執行狀態的數據流。
    public private(set) lazy var setBikeStatusStateSubject: CurrentValueSubject<Bool?, Never> = {
        .init(nil)
    }()
    
    /// 設定車輛為手動診斷狀態時，命令執行狀態的數據流。
    public private(set) lazy var setManualTestStateSubject: CurrentValueSubject<Bool?, Never> = {
        .init(nil)
    }()
    
    /// 取得電池資訊時，命令執行狀態的數據流。
    public private(set) lazy var readBatteryInfoStateSubject: CurrentValueSubject<Bool?, Never> = {
        .init(nil)
    }()
    
    /// 重置車輛騎乘參數設定，命令執行狀態的數據流。
    public private(set) lazy var resetRideConfigStateSubject: CurrentValueSubject<Bool?, Never> = {
        .init(nil)
    }()
    
    /// 重置保養里程紀錄，命令執行狀態的數據流。
    public private(set) lazy var resetMaintenanceMileageStateSubject: CurrentValueSubject<Bool?, Never> = {
        .init(nil)
    }()
    
    public private(set) lazy var setScreenAccessControlStateSubject: CurrentValueSubject<CoreSDKService.ScreenLockState?, Swift.Error> = {
        .init(nil)
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
    
    internal static var writingStringData: [UInt8] = .init()
    
    internal static var writingIntData: Int = .init()
    
    internal static var writingIntArrayData: [Int8] = .init()
    
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
        _ = self.dataBus?.bleCommandPacketIn(data: &data, length: UInt32(dataPacket.count))
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
            let bleCommandPacketOutResult: Int32? = self.dataBus?.bleCommandPacketOut(
                data: &self.commandPacketOutData,
                length: &self.commandPacketOutDataLeng
            )
            
            if let result: Int32 = bleCommandPacketOutResult, result == SDK_RETURN_SUCCESS.rawValue {
                // 要把處理過的原始封包丟給 BleSDK 去傳給 Hmi
                let length: Int = .init(self.commandPacketOutDataLeng)
                let bytes: [UInt8] = self.commandPacketOutData.convert2Bytes(length: length)
                self.commandPacketSubject.send(bytes)
            }
            
            // 接收 sdk 處理後的 bin 檔 data，主要是更新 fw 會使用到
            do {
                let bleDataPacketOutResult: Int32? = try self.dataBus?.bleDataPacketOut(
                    data: &self.dataPacketOutData,
                    length: &self.dataPacketOutDataLeng
                )
                
                if let result: Int32 = bleDataPacketOutResult, result == SDK_RETURN_SUCCESS.rawValue {
                    let length: Int = .init(self.dataPacketOutDataLeng)
                    let bytes: [UInt8] = self.dataPacketOutData.convert2Bytes(length: length)
                    self.commandPacketSubject.send(bytes)
                }
            } catch {
                print("AppleBikeKit[startReadWriteChannel]: \(error)")
            }
        })
    }
    
    /**
     建構子。
     */
    public init(target: String) {
        // 檢查新值是否為空。
        guard !target.isEmpty else {
            fatalError("配置目標(target)不可為空。")
        }
        
        // 嘗試將新值轉換為`Tenant`枚舉
        let tenant: Tenant = .from(target)
        guard tenant != .unknown else {
            fatalError("未知的配置目標(target)。")
        }
        
        self.tenant = tenant
        
        super.init()
        
        print("AppleBikeKit[CoreSdkService]: init")
        
        Self.dataSource = self
        self.initCoreSDK()
        self.enableSDK()
        
        switch tenant {
        case .farmland, .merida:
            // 將數據通道設置為對應於 Farmland 的專有數據通道。
            self.dataBus = self.coreSDKInst.DataBus.Apple
            self.delegateFunction = self.coreSDKInst.DelegateMethod.Apple
        case .lexy:
            // 將數據通道設置為對應於 Lexy 的專有數據通道。
            self.dataBus = self.coreSDKInst.DataBus.Apple  // Orange 與 Apple 共用。
            self.delegateFunction = self.coreSDKInst.DelegateMethod.Orange
        case .mivice:
            // 將數據通道設置為對應於 Mivice 的專有數據通道。
            self.dataBus = self.coreSDKInst.DataBus.Cherry
            self.delegateFunction = self.coreSDKInst.DelegateMethod.Cherry
        case .unknown:
            // 由於未知的配置目標，這裡採用了防禦式編程，直接觸發錯誤。
            // 這確保了應用不會在未知的配置狀態下運行，避免可能的錯誤或不可預測的行為。
            fallthrough
        @unknown default:
            // 為了未來擴展性，捕捉任何未知的配置案例。
            // 直接觸發錯誤，因為未處理的配置可能會導致應用不穩定或數據處理問題。
            fatalError("未知的配置目標(target)。")
        }
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
        print("AppleBikeKit[InitializingCoreSDK]: \(String(describing: self.sdkVersion))")
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
        let isCoreSDKCompleteTask: Int32? = try self.delegateFunction?.readParameters(return_state: SDK_ROUTER_BLE, target_device: parameter.partType.coreType, addr: parameter.address, leng: parameter.length, bank_index: parameter.bank, callback: self.readParameterEvent)
        guard let isCoreSDKCompleteTask: Int32, isCoreSDKCompleteTask == 0 else {
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
            
            Self.writingStringData = .init(repeating: 0, count: .init(parameter.length))
            for (index, char) in parameterValue.utf8.enumerated() {
                guard index < Self.writingStringData.count else {
                    throw Self.Error.writeTextOutOfRange
                }
                Self.writingStringData[index] = char
            }
            
            let isCoreSDKCompleteTask: Int32? = try self.delegateFunction?.writeStringParameters(router: SDK_ROUTER_BLE, target_device: parameter.partType.coreType, addr: parameter.address, leng: parameter.length, bank_index: parameter.bank, callback: self.writeParameterEvent)
            
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
            
            Self.writingIntData = parameterValue
            
            var isCoreSDKCompleteTask: Int32?
            
            let unsafeMutableRawPointer = UnsafeMutableRawPointer.allocate(byteCount: MemoryLayout<Int32>.stride * 2, alignment: MemoryLayout<Int>.alignment)
            unsafeMutableRawPointer.storeBytes(of: parameterValue, as: Int.self)
            
            isCoreSDKCompleteTask = try self.delegateFunction?.writeIntParameters(router: SDK_ROUTER_BLE, target_device: parameter.partType.coreType, addr: parameter.address, leng: parameter.length, bank_index: parameter.bank, callback: self.writeParameterEvent)
            
            guard let isCoreSDKCompleteTask: Int32, isCoreSDKCompleteTask == 0 else {
                throw Self.Error.writeParameterFail(parameter)
            }
        } else if let _ = parameter.type as? [Int].Type {
            // 確認 parameter 的 value 屬性能成功轉型為 [Int]，且 dividedParameters 存在，否則拋出錯誤。
            guard let values = parameter.value as? [Int], let dividedParameters = parameter.dividedParameters else {
                throw Self.Error.writeParameterWithNoValue
            }
            
            // 根據 values 的數量和 Int 的 stride 計算所需的內存大小。
            let byteCount = MemoryLayout<Int8>.stride * values.count
            
            // 確保計算出來的內存大小有效，否則拋出錯誤。
            guard byteCount > 0 else {
                throw Self.Error.writeParameterWithInvalidSize
            }
            
            print("總共需要分配的內存長度：\(byteCount) bytes")
            
            // 將 values 存入 Self.writingIntArrayData 供後續操作使用。
            Self.writingIntArrayData = values.map({ Int8($0) })
            
            // 分配 byteCount 大小的內存，並使用 Int 的對齊方式來進行內存分配。
            let unsafeMutableRawPointer = UnsafeMutableRawPointer.allocate(byteCount: byteCount, alignment: MemoryLayout<Int>.alignment)
            defer {
                unsafeMutableRawPointer.deallocate() // 確保函數結束後內存能正確釋放。
            }
            
            // 使用 withUnsafeBytes 來將 values 中的數據複製到分配的內存中。
            values.withUnsafeBytes { bufferPointer in
                unsafeMutableRawPointer.copyMemory(from: bufferPointer.baseAddress!, byteCount: byteCount)
            }
            
            // 調用 delegateFunction 的 writeIntArrayParameters 方法，並傳遞所需參數進行寫入操作。
            var isCoreSDKCompleteTask: Int32?
            isCoreSDKCompleteTask = try self.delegateFunction?.writeIntArrayParameters(
                router: SDK_ROUTER_BLE,
                target_device: parameter.partType.coreType,
                addr: parameter.address,
                leng: UInt16(values.count), // 傳遞數據長度
                bank_index: parameter.bank,
                callback: self.writeParameterEvent
            )
            
            // 檢查 isCoreSDKCompleteTask 是否執行成功，否則拋出錯誤。
            guard let isCoreSDKCompleteTask = isCoreSDKCompleteTask, isCoreSDKCompleteTask == 0 else {
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
        let isCoreSDKCompleteTask: Int32? = try self.delegateFunction?.restartDevice(router: SDK_ROUTER_BLE, target_device: part.coreType, callback: self.restartPartEvent)
        guard let isCoreSDKCompleteTask: Int32, isCoreSDKCompleteTask == 0 else {
            throw Self.Error.restartPartFail(part)
        }
    }
    
    /**
     重置里程參數。
     */
    public func resetTripInfo() throws {
        let isCoreSDKCompleteTask: Int32? = try self.delegateFunction?.clearTripInfo(router: SDK_ROUTER_BLE, callback: self.resetTripInfoEvent)
        guard let isCoreSDKCompleteTask: Int32, isCoreSDKCompleteTask == 0 else {
            throw Self.Error.resetTripInfoFail
        }
    }
    
    /**
     重置部件參數。
     */
    public func resetPartParameter(part: CommunicationPartType, bank: Int) throws {
        let isCoreSDKCompleteTask: Int32? = try self.delegateFunction?.resetParameters(router: SDK_ROUTER_BLE, target_device: part.coreType, bank_index: UInt8(bank), callback: self.resetPartParameterEvent)
        guard let isCoreSDKCompleteTask: Int32, isCoreSDKCompleteTask == 0 else {
            throw Self.Error.resetPartParameterFail(part, bank)
        }
    }
    
    /**
     校正電控時間。
     */
    public func updateSystemTime() throws {
        let time: UInt64 = .init(Date().timeIntervalSince1970)
        let isCoreSDKCompleteTask: Int32? = try self.delegateFunction?.configSystemTime(router: SDK_ROUTER_BLE, target_device: SDK_FL_MAIN_BATT, unix_time: time, callback: self.updateSystemTimeEvent)
        guard let isCoreSDKCompleteTask: Int32, isCoreSDKCompleteTask == 0 else {
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
        let isCoreSDKCompleteTask: Int32? =  try self.delegateFunction?.lightControl(router: SDK_ROUTER_BLE, parts: part, on_off: isOn, callback: self.lightControlEvent)
        guard let isCoreSDKCompleteTask: Int32, isCoreSDKCompleteTask == 0 else {
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
        
        let isCoreSDKCompleteTask: Int32? =  try self.delegateFunction?.upgradeFirmware(router: SDK_ROUTER_BLE, target_device: part.coreType, device_MID: midPointer, data: dataPointer, data_size: UInt32(data.count), upgrade_msg_callback: self.upgradeFirmwareProgress, callback: self.upgradeFirmwareEvent)
        guard let isCoreSDKCompleteTask: Int32, isCoreSDKCompleteTask == 0 else {
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
        let isCoreSDKCompleteTask: Int32? =  try self.delegateFunction?.getELock(router: SDK_ROUTER_BLE, callback: self.getELockEvent)
        guard let isCoreSDKCompleteTask: Int32, isCoreSDKCompleteTask == 0 else {
            throw Self.Error.getELockFail
        }
    }
    
    /**
     設定電子鎖狀態。
     
     - parameter release: 防誤觸定位閂鎖。
     - parameter unlocked: 是否解鎖。
     - Throws: CoreSDK 執行失敗。
     */
    public func setELock(release: Bool, unlocked: Bool) throws {
        let isCoreSDKCompleteTask: Int32? =  try self.delegateFunction?.setELock(router: SDK_ROUTER_BLE, release: release, unlocked: unlocked, callback: self.setELockEvent)
        guard let isCoreSDKCompleteTask: Int32, isCoreSDKCompleteTask == 0 else {
            throw Self.Error.setELockFail
        }
    }
    
    /**
     設定助力段數。
     
     - Throws: CoreSDK 執行失敗。
     */
    public func setAssistLevel(_ level: UInt8) throws {
        let isCoreSDKCompleteTask: Int32? =  try self.delegateFunction?.setAssistLevel(router: SDK_ROUTER_BLE, set_level: level, callback: self.setAssistLevelEvent)
        guard let isCoreSDKCompleteTask: Int32, isCoreSDKCompleteTask == 0 else {
            throw Self.Error.setAssistLevelFail
        }
    }
    
    /**
     校正電控時間。
     
     - Attention: from Orange_DelegateFuncDefine_T
     
     - Throws: CoreSDK 執行失敗。
     */ 
    public func configSystemTime() throws {
        guard let delegateFunction = self.delegateFunction as? Orange_DelegateFuncDefine_T else {
            throw Self.Error.castingDelegateFunctionFail
        }
        let time: UInt64 = .init(Date().timeIntervalSince1970)
        let offset: Int = TimeZone.current.secondsFromGMT()
        let isCoreSDKCompleteTask: Int32? = try delegateFunction.configSystemTime(
            router: SDK_ROUTER_BLE, 
            target_device: nil,
            unix_time: time + UInt64(offset),
            callback: self.updateSystemTimeEvent)
        guard let isCoreSDKCompleteTask: Int32, isCoreSDKCompleteTask == 0 else {
            throw Self.Error.updateSystemTimeFail
        }
    }
    
    /**
     重置參數。
     
     - Attention: from Orange_DelegateFuncDefine_T
     
     - Throws: CoreSDK 執行失敗。
     */
    public func resetDeviceParameter() throws {
        guard let delegateFunction = self.delegateFunction as? Orange_DelegateFuncDefine_T else {
            throw Self.Error.castingDelegateFunctionFail
        }
        let isCoreSDKCompleteTask: Int32? = try delegateFunction.resetDeviceParam(router: SDK_ROUTER_BLE, callback: self.resetDeviceParameterEvent)
        guard let isCoreSDKCompleteTask: Int32, isCoreSDKCompleteTask == 0 else {
            throw Self.Error.resetDeviceParameterFail
        }
    }
    
    /**
     設定車輛狀態。
     
     - Attention: from Orange_DelegateFuncDefine_T
     
     - parameter status: 車輛狀態。預設值為自動診斷。
     - Throws: CoreSDK 執行失敗。
     */
    public func setBikeStatus(_ status: ORANGE_BIKE_STATUS_E = ORANGE_BIKE_STATUS_AUTO_TEST) throws {
        guard let delegateFunction = self.delegateFunction as? Orange_DelegateFuncDefine_T else {
            throw Self.Error.castingDelegateFunctionFail
        }
        let isCoreSDKCompleteTask: Int32? = try delegateFunction.setBikeStatus(router: SDK_ROUTER_BLE, set_status: status, callback: self.setBikeStatusEvent)
        guard let isCoreSDKCompleteTask: Int32, isCoreSDKCompleteTask == 0 else {
            throw Self.Error.setBikeStatusFail
        }
    }
    
    /**
     設定車輛為手動診斷狀態。
     
     - Attention: from Orange_DelegateFuncDefine_T
     
     - parameter type: 手動測試指令。
     - Throws: CoreSDK 執行失敗。
     */
    public func setManualTest(type: ORANGE_MANUAL_TEST_TYPE_E) throws {
        guard let delegateFunction = self.delegateFunction as? Orange_DelegateFuncDefine_T else {
            throw Self.Error.castingDelegateFunctionFail
        }
        let isCoreSDKCompleteTask: Int32? = try delegateFunction.setManualTest(router: SDK_ROUTER_BLE, command: type, callback: self.setManualTestEvent)
        guard let isCoreSDKCompleteTask: Int32, isCoreSDKCompleteTask == 0 else {
            throw Self.Error.setManualTestFail
        }
    }
    
    /**
     取得電池資訊。
     
     - Attention: from Orange_DelegateFuncDefine_T
     
     - Throws: CoreSDK 執行失敗。
     */
    public func readBatteryInfo() throws {
        guard let delegateFunction = self.delegateFunction as? Orange_DelegateFuncDefine_T else {
            throw Self.Error.castingDelegateFunctionFail
        }
        let isCoreSDKCompleteTask: Int32? = try delegateFunction.readBatteryInfo(router: SDK_ROUTER_BLE, callback: self.readBatteryInfoEvent)
        guard let isCoreSDKCompleteTask: Int32, isCoreSDKCompleteTask == 0 else {
            throw Self.Error.readBatteryInfoFail
        }
    }
    
    /**
     重置。
     
     - Attention: from Orange_DelegateFuncDefine_T
     - Note: 如有疑問，可參閱通訊協議。
     
     - Parameter type: 0 = 騎乘紀錄; 1 = 車輛設置; 2 = 保養里程。
     - Throws: CoreSDK 執行失敗。
     */
    public func resetBikeSettings(_ type: UInt8) throws {
        guard let delegateFunction: Orange_DelegateFuncDefine_T = self.delegateFunction as? Orange_DelegateFuncDefine_T else {
            throw Self.Error.castingDelegateFunctionFail
        }
        let isCoreSDKCompleteTask: Int32? = try delegateFunction.resetBikeSettings(router: SDK_ROUTER_BLE, reset_type: type, callback: self.resetRideConfigEvent)
        guard let isCoreSDKCompleteTask: Int32, isCoreSDKCompleteTask == 0 else {
            throw Self.Error.resetRideConfigFail
        }
    }
    
    public func setScreenAccessControl(_ accessControl: CoreSDKService.ScreenLockState) throws {
        guard let delegateFunction = self.delegateFunction as? Apple_DelegateFuncDefine_T else {
            throw Self.Error.castingDelegateFunctionFail
        }
        var isCoreSDKCompleteTask: Int32?
        switch accessControl {
        case .lock:
            isCoreSDKCompleteTask = try delegateFunction.setScreenAccessControl(router: SDK_ROUTER_BLE, device: SDK_FL_HMI, action: 1, password: .allocate(capacity: 4), callback: setHMIAccessControlEvent)
        case .unlock(let password):
            Self.writingStringData = .init(repeating: 0, count: 4)

            // 寫入字串的 UTF-8 編碼到緩衝區
            for (index, char) in password.utf8.enumerated() {
                guard index < Self.writingStringData.count else {
                    throw Self.Error.writeTextOutOfRange
                }
                Self.writingStringData[index] = char
            }

            // 正確地傳遞指針
            Self.writingStringData.withUnsafeMutableBufferPointer { bufferPointer in
                guard let baseAddress = bufferPointer.baseAddress else {
                    fatalError("Failed to get base address of writingStringData")
                }

                do {
                    isCoreSDKCompleteTask = try delegateFunction.setScreenAccessControl(
                        router: SDK_ROUTER_BLE,
                        device: SDK_FL_HMI,
                        action: 2,
                        password: baseAddress,
                        callback: self.setHMIAccessControlEvent
                    )
                } catch {
                    print("Error calling setScreenAccessControl: \(error)")
                }
            }
        }
        guard let isCoreSDKCompleteTask: Int32, isCoreSDKCompleteTask == 0 else {
            throw Self.Error.setHMIAccessControlFail
        }
    }
    
    public func resetScreenAccessControl() throws {
        guard let delegateFunction = self.delegateFunction as? Apple_DelegateFuncDefine_T else {
            throw Self.Error.castingDelegateFunctionFail
        }
        let isCoreSDKCompleteTask: Int32? = try delegateFunction.resetScreenAccessControl(router: SDK_ROUTER_BLE, device: SDK_FL_HMI, callback: self.resetHMIAccessControlEvent)
        guard let isCoreSDKCompleteTask: Int32, isCoreSDKCompleteTask == 0 else {
            throw Self.Error.resetScreenAccessControlFail
        }
    }
}

// MARK: - CoreSDK Protocol

extension CoreSDKService: CoreSDKDataSource {
    
    func updateDeviceInfo(deviceInfo: DeviceInformation_T) {
        switch tenant {
        case .farmland, .merida:
            self.getElockStateSubject.send(deviceInfo.Apple.e_lock_states)
            self.deviceInfoSubject.value = (deviceInfo.Apple, .init())
        case .lexy:
            self.deviceInfoSubject.value = (deviceInfo.Orange, .init())
            break
        case .mivice:
            self.deviceInfoSubject.value = (deviceInfo.Cherry, .init())
            break
        case .unknown:
            // 由於未知的配置目標，這裡採用了防禦式編程，直接觸發錯誤。
            // 這確保了應用不會在未知的配置狀態下運行，避免可能的錯誤或不可預測的行為。
            fallthrough
        @unknown default:
            // 為了未來擴展性，捕捉任何未知的配置案例。
            // 直接觸發錯誤，因為未處理的配置可能會導致應用不穩定或數據處理問題。
            fatalError("未知的配置目標(target)。")
        }
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
    
    func setELock(state: Bool) {
        self.setELockStateSubject.send(state)
    }
    
    func setAssistLevel(state: Bool) {
        self.setAssistLevelStateSubject.send(state)
    }
    
    func resetDeviceParameter(state: Bool) {
        self.resetDeviceParameterStateSubject.send(state)
    }
    
    func setBikeStatus(state: Bool) {
        self.setBikeStatusStateSubject.send(state)
    }
    
    func setManualTest(state: Bool) {
        self.setManualTestStateSubject.send(state)
    }
    
    func readBatteryInfo(state: Bool) {
        self.readBatteryInfoStateSubject.send(state)
    }
    
    func resetRideConfig(state: Bool) {
        self.resetRideConfigStateSubject.send(state)
    }
    
    func resetMaintenanceMileage(state: Bool) {
        self.resetMaintenanceMileageStateSubject.send(state)
    }
    
    func setScreenAccessControl(state: Bool, device: SDKDeviceType_e, action: Int, password: String) {
        if state, action == 1 {
            self.setScreenAccessControlStateSubject.send(.lock)
        } else if state, action == 2 {
            self.setScreenAccessControlStateSubject.send(.unlock(password))
        } else {
            self.setScreenAccessControlStateSubject.send(completion: .failure(CoreSDKService.Error.setHMIAccessControlFail))
        }
    }

    func resetScreenAccessControl(state: Bool, device: SDKDeviceType_e) {
        #warning("待完成")
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
        /// 更新電子鎖狀態失敗。
        case setELockFail
        /// 設定助力段數失敗。
        case setAssistLevelFail
        /// 映射指令函式的實例失敗。
        case castingDelegateFunctionFail
        /// 重置參數失敗。(Lexy)
        case resetDeviceParameterFail
        /// 設置車輛狀態失敗。(Lexy)
        case setBikeStatusFail
        /// 設置手動測試失敗。(Lexy)
        case setManualTestFail
        /// 讀取電池資訊失敗。(Lexy)
        case readBatteryInfoFail
        /// 重置車輛騎乘參數設定失敗。(Lexy)
        case resetRideConfigFail
        /// 重置保養里程紀錄。(Lexy)
        case resetMaintenanceMileageFail
        
        case writeParameterWithInvalidSize
        
        case setHMIAccessControlFail
        
        case resetScreenAccessControlFail
    }
}

// MARK: - 取得 CoreSDK 回調的委派協定

/// CoreSDKService 操作 CoreSDK 時，需透過委派來取得回調的資訊。
private protocol CoreSDKDataSource: AnyObject {
    
    /// 刷新腳踏車資訊時，回調的資訊。
    func updateDeviceInfo(deviceInfo: DeviceInformation_T)
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
    /// 設定電子鎖狀態。
    func setELock(state: Bool)
    /// 設定助力段數。
    func setAssistLevel(state: Bool)
    /// 重置參數。
    func resetDeviceParameter(state: Bool)
    /// 設定車輛狀態。
    func setBikeStatus(state: Bool)
    /// 設定車輛為手動診斷狀態。
    func setManualTest(state: Bool)
    /// 取得電池資訊。
    func readBatteryInfo(state: Bool)
    /// 重置車輛騎乘參數設定。
    func resetRideConfig(state: Bool)
    /// 重置保養里程紀錄
    func resetMaintenanceMileage(state: Bool)
    
    func setScreenAccessControl(state: Bool, device: SDKDeviceType_e, action: Int, password: String)
    
    func resetScreenAccessControl(state: Bool, device: SDKDeviceType_e)
}
