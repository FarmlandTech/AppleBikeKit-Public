//
//  FarmLandBikeKit.swift
//  
//
//  Created by Jeff Chiu on 2023/5/21.
//

import Foundation
import Combine
import MapKit

import CoreBLEServiceSourceCode
import AppleBikeKit
import CoreSDKSourceCode
import CoreSDKServiceSourceCode

/// 農田應用程式開發套件，常見需求的集成。
open class FarmLandBikeKit: AppleBikeKit {
    
    public enum HMIAccessControl: UInt32 {
        case lock = 0
        case unlock
        case disable
        case unknown
    }
    
    /// 自定義錯誤。
    public enum Error: Swift.Error {
        case DisguiseBatteryHelperIsNil
        case unsupportedLevel
        case deviceInfoUnavailable
        case functionNotExist(String)
        case deviceNotUnlocked
        case screenLockTokenCorrupted
        case screenLockTokenIsNotAllowed
        /// 助力檔位超出定義範圍。
        case assistLevelOutOfBounds
        /// 非預期的助力檔位。
        case assistLevelUnexpected
        /// 檔位助力比超出定義範圍。
        case assistRatioOutOfBounds
        /// 檔位速限超出定義範圍。
        case speedOutOfLimitation
        /// 自動休眠時間超出定義範圍
        case sleepTimeOutOfBounds(TimeInterval)
        
        case isBLEDisconnecting
        
        case getNoAssistParameterName
        case getNoAssistValue(ParameterData.Apple.Name)
        /// 緩啟動檔位超出定義範圍。
        case staOutOfBounds
        /// 邏輯進行中。(避免重複的異步操作)
        case isProccessing
    }
    
    /// 單例。
    public static let sleipnir: FarmLandBikeKit = .init()
    
    /// 關鍵參數(ssn或dmid等)的緩存值。
    public var metaParameter: MetaParameter {
        self.connectionMetaReadingHelper.metaSubject.value
    }
    
    /// 取得關鍵參數(ssn或dmid等)的處理物件實例。
    private lazy var connectionMetaReadingHelper: ConnectionMetaReadingHelper = {
        .init()
    }()
    
    /// 更新電控時間的處理物件實例。
    private lazy var systemTimeUpdateHelper: SystemTimeUpdateHelper = {
        .init()
    }()
    
    /// 存取距離單位(公制or英制)座標系統的處理物件實例。
    private lazy var metricSystemManipulateHelper: MetricSystemManipulateHelper = {
        .init()
    }()
    
    /// 存取助力等級的處理物件實例。
    private lazy var assistPlanUpdateHelper: AssistPlanUpdateHelper = {
        .init()
    }()
    
    /// 判斷 BMS 是否具有通訊功能的處理物件實例。
    private lazy var disguiseBatteryHelper: DisguiseBatteryHelper? = {
        do {
            return try .init()
        } catch {
            print("\(error)")
            return nil
        }
    }()
    
    /// 關鍵參數的 Publisher 。
    public private(set) lazy var metaPublisher: AnyPublisher<MetaParameter, Never> = {
        self.connectionMetaReadingHelper.metaSubject.removeDuplicates().eraseToAnyPublisher()
    }()
    
    /// 助力等級讀取狀態的 Publisher 。
    public private(set) lazy var assistLevelRepositoryReadingPublisher: AnyPublisher<AssistPlanUpdateHelper.ReadingResult<AssistLevelRepository?>, Never> = {
        self.assistPlanUpdateHelper.readingSubject
            .eraseToAnyPublisher()
    }()
    
    /// 助力等級寫入狀態的 Publisher 。
    public private(set) lazy var assistLevelRepositoryWritingPublisher: AnyPublisher<AssistPlanUpdateHelper.WritingResult<AssistLevelRepository?>, Never> = {
        self.assistPlanUpdateHelper.writingSubject
            .eraseToAnyPublisher()
    }()
    
    /// 單日里程(chart)的 /// 判斷 BMS 是否具有通訊功能的處理物件實例。 。
    public private(set) lazy var odoChartDataPublisher: AnyPublisher<Result<[MileageRecord], Swift.Error>, Swift.Error> = {
        guard FarmLandBikeKit.tenant == .apple || FarmLandBikeKit.tenant == .kiwi else {
            return Fail(error: FarmLandBikeKit.Error.functionNotExist(#function))
                .map({ Result<[MileageRecord], Swift.Error>.failure($0) })
                .eraseToAnyPublisher()
        }
        return self.parameterDataPublisher
            .filter({ $0.name == ParameterData.Apple.Name.INTEGRATED_MILEAGE_RECORD.rawValue })
            .compactMap({ parameterData in
                self.parameterDataRepository.parameters.firstIndex(where: { $0.name == parameterData.name })
            })
            .compactMap({ index in
                self.parameterDataRepository.parameters[index].dividedParameters
            })
            .map({
                do {
                    return Result<[MileageRecord], Swift.Error>.success(try $0.transfer2MileageRecords())
                } catch {
                    return Result<[MileageRecord], Swift.Error>.failure(error)
                }
            })
            .eraseToAnyPublisher()
    }()
    
    /// 判斷 BMS 是否具有通訊功能的 Publisher 。
    public private(set) lazy var disguiseBatteryPublisher: AnyPublisher<DisguiseBatteryHelper.ReadingResult<Bool?>, Never>? = {
        self.disguiseBatteryHelper?.readingSubject
            .eraseToAnyPublisher()
    }()
    
    public private(set) lazy var screenLockPublisher: AnyPublisher<(errorCount: Int, state: FarmLandBikeKit.HMIAccessControl), Swift.Error> = {
        self.deviceInfoPublisher()
            .compactMap({ $0.deviceInfo })
            .tryMap({ try $0.asAppleDeviceInfo() })
            .removeDuplicates(by: {
                $0.screen_lock_error_count == $1.screen_lock_error_count && $0.screen_lock_state == $1.screen_lock_state
            })
            .map({
                switch $0.screen_lock_state {
                case 0:
                    return (errorCount: .init($0.screen_lock_error_count), state: FarmLandBikeKit.HMIAccessControl.lock)
                case 1:
                    return (errorCount: .init($0.screen_lock_error_count), state: FarmLandBikeKit.HMIAccessControl.unlock)
                case 2:
                    return (errorCount: .init($0.screen_lock_error_count), state: FarmLandBikeKit.HMIAccessControl.disable)
                default:
                    return (errorCount: .init($0.screen_lock_error_count), state: FarmLandBikeKit.HMIAccessControl.unknown)
                }
            })
            .eraseToAnyPublisher()
    }()
    
    public override func doTasks() {
        super.doTasks()
        
        // 監聽連線狀態。
        self.peripheralPublisher.sink(receiveValue: { status in
            switch status {
            case .unknown:
                break
            case .didConnect(_):
                break
            case .prepared:  // 取得關鍵參數。
                do {
                    try self.connectionMetaReadingHelper.doTask()
                } catch {
                    // TODO: 錯誤處理？
                    assertionFailure("\(error)")
                }
                do {
                    try self.systemTimeUpdateHelper.doTask()
                } catch {
                    print(error)
                }
            case .didDisconnect(_):  // 清空緩存數據。
                self.connectionMetaReadingHelper.metaSubject.send(.init())
                self.systemTimeUpdateHelper.stateSubject.send(nil)
            }
        }).store(in: &self.subscriptions)
        
//        // 監聽裝置資訊。
//        self.deviceInfoPublisher().sink(receiveValue: { deviceInfo in
//
//        }).store(in: &self.subscriptions)
    }
    
    public func setMetaWhitelist(_ whitelist: [(name: String, part: CommunicationPartType)]) {
        self.connectionMetaReadingHelper.parameterWhitelist = whitelist
    }
    
    /**
     執行藍牙連線。
     */
    public func connectBike(_ peripheral: BluetoothPeripheral) -> AnyPublisher<Int, Swift.Error> {
        self.scanningPublisher
            .first()
            .flatMap({
                if $0 {
                    self.stopScan()
                    return self.scanningPublisher
                        .filter({ !$0 })
                        .first()
                        .setFailureType(to: Swift.Error.self)
                        .eraseToAnyPublisher()
                } else {
                    return Just(false)
                        .setFailureType(to: Swift.Error.self)
                        .eraseToAnyPublisher()
                }
            })
            .handleEvents(receiveOutput: { _ in
                self.connect(peripheral)
            })
            .map({ _ in
                let mtuSize = peripheral.device.maximumWriteValueLength(for: .withoutResponse) + 3
                return mtuSize
            })
            .eraseToAnyPublisher()
    }
    
    /**
     執行藍牙斷線。
     */
    public func disconnectBike() {
        guard let peripheral: BluetoothPeripheral = self.connectedPeripheral.currentPeripheral else { return }
        self.disconnect(peripheral)
    }
    
    /**
     更新電控時間。
     
     - Throws: 上次的讀取仍然在執行(或重試)，便會拋出錯誤；如果底層 AppleBikeKit 讀取參數時，設定錯誤，也可能會拋出錯誤。
     */
    public func updateMetaParameter() throws {
        try self.connectionMetaReadingHelper.doTask()
    }
    
    /**
     設定距離單位(公制or英制)座標系統。
     
     - parameter isMetricSystem: 是否為公制。
     - Throws: 上次的寫入仍然在執行(或重試)，便會拋出錯誤；如果底層 AppleBikeKit 寫入參數時，設定錯誤，也可能會拋出錯誤。
     */
    public func writeMetricSystem(_ isMetricSystem: MKDistanceFormatter.Units) throws {
        try self.metricSystemManipulateHelper.write(isMetricSystem)
    }
    
    /**
     讀取助力等級當前的數值。
     
     - Throws: 上次的讀取仍然在執行(或重試)，便會拋出錯誤；如果底層 AppleBikeKit 讀取參數時，設定錯誤，也可能會拋出錯誤。
     */
    public func readAssistLevel() throws {
        try self.assistPlanUpdateHelper.read()
    }
    
    /**
     寫入助力等級。
     
     - parameter LV1_AST_RATIO: 第一段助力的數值。
     - parameter LV2_AST_RATIO: 第二段助力的數值。
     - parameter LV3_AST_RATIO: 第三段助力的數值。
     - Throws: 上次的寫入仍然在執行(或重試)，便會拋出錯誤；如果底層 AppleBikeKit 寫入參數時，設定錯誤，也可能會拋出錯誤。
     */
    public func writeAssistLevel(LV1_AST_RATIO: Int, LV2_AST_RATIO: Int, LV3_AST_RATIO: Int) throws {
        try self.assistPlanUpdateHelper.write(
            LV1_MAX_AST_RATIO: LV1_AST_RATIO,
            LV1_MIN_AST_RATIO: LV1_AST_RATIO / 2,
            LV2_MAX_AST_RATIO: LV2_AST_RATIO,
            LV2_MIN_AST_RATIO: LV2_AST_RATIO / 2,
            LV3_MAX_AST_RATIO: LV3_AST_RATIO,
            LV3_MIN_AST_RATIO: LV3_AST_RATIO / 2
        )
    }
    
    /**
     讀取單日里程(chart)的數據。
     
     - Throws: 上次的讀取仍然在執行(或重試)，便會拋出錯誤；如果底層 AppleBikeKit 讀取參數時，設定錯誤，也可能會拋出錯誤。
     */
    public func readODOChartData() throws {
        
        let functionName: String = #function
        guard FarmLandBikeKit.tenant == .apple || FarmLandBikeKit.tenant == .kiwi else {
            throw FarmLandBikeKit.Error.functionNotExist(functionName)
        }
        
        try self.readParameter(name: ParameterData.Apple.Name.INTEGRATED_MILEAGE_RECORD.rawValue, part: .MainBatt)
    }
    
    /**
     控制車燈開關。
     
     - parameter part: 前燈或後燈。
     - parameter isOn: 開或關。
     - Throws: CoreSDK 執行失敗，或部件版本並未支持此功能。
     */
    public override func lightControl(part: light_control_parts = LIGHT_CONTROL_FRONT, isOn: Bool) throws {
//        try self.checkVersion(part: .controller, version: "0.0.22")
//        try self.checkVersion(part: .hmi, version: "0.0.20")
        try super.lightControl(part: part, isOn: isOn)
    }
    
    /**
     讀取 BMS 是否具有通訊功能的狀態。
     
     - Throws: 參數找不到，或 CoreSDK 執行失敗。
     */
    public func readDisguiseBatteryStatus() throws {
        guard let disguiseBatteryHelper: DisguiseBatteryHelper else {
            throw Self.Error.DisguiseBatteryHelperIsNil
        }
        try disguiseBatteryHelper.read()
    }
    
    /**
     設置輔助等級。

     - Important: 請確保輸入的輔助等級在設備支援的範圍內。
     - Attention: 如果設備信息不可用或輸入的輔助等級超出支援範圍，將會拋出錯誤。
     - Requires: `info.deviceInfo` 必須不為 `nil`，且 `support_assist_lv` 必須大於或等於輸入的等級。

     - parameter level: 欲設置的輔助等級。
     - Throws: `FarmLandBikeKit.Error.deviceInfoUnavailable` 如果設備信息不可用。
              `FarmLandBikeKit.Error.unsupportedLevel` 如果輸入的等級超出設備支援範圍。
     */
    public override func setAssistLevel(_ level: UInt8) -> AnyPublisher<Void, Swift.Error> {
        switch FarmLandBikeKit.tenant {
        case .apple, .kiwi:
            return self.deviceInfoPublisher()
                .first()
                .compactMap({ $0.deviceInfo })
                .setFailureType(to: Swift.Error.self)
                .tryMap({ try $0.asAppleDeviceInfo() })
                .tryMap({ (appleDeviceInfo: Apple_Info_st) -> Apple_Info_st in
                    switch appleDeviceInfo.screen_lock_state {
                    case 0, 2:
                        throw FarmLandBikeKit.Error.deviceNotUnlocked
                    default:
                        return appleDeviceInfo
                    }
                })
                .tryMap({ (appleDeviceInfo: Apple_Info_st) -> Apple_Info_st in
                    if appleDeviceInfo.support_assist_lv >= UInt32(level) {
                        return appleDeviceInfo
                    } else {
                        throw FarmLandBikeKit.Error.unsupportedLevel
                    }
                })
                .flatMap({ _ -> AnyPublisher<Void, Swift.Error> in
                    super.setAssistLevel(level)
                })
                .eraseToAnyPublisher()
        case .orange:
            let name: ParameterData.Orange.Controller.Bank1 = .MAX_ASSIST_LV
            do {
                try self.readParameter(name: name.rawValue, part: .Controller)
            } catch {
                return Fail<Void, Swift.Error>(error: error)
                    .eraseToAnyPublisher()
            }
            return self.parameterDataPublisher
                .filter({ $0.name == name.rawValue && $0.partType == .Controller })
                .first()
                .compactMap({ $0.value as? UInt8 })
                .tryMap({ (value: UInt8) -> Void in
                    if value >= level {
                        return Void()
                    } else {
                        throw FarmLandBikeKit.Error.unsupportedLevel
                    }
                })
                .flatMap({ _ -> AnyPublisher<Void, Swift.Error> in
                    super.setAssistLevel(level)
                })
                .eraseToAnyPublisher()
        default:
            fatalError("未授權的使用： \(#function)")
        }
    }
    
    public func getHmiPasswordCode() -> AnyPublisher<[Int]?, Swift.Error> {
        self.screenLockPublisher
            .compactMap({ $0.state })
            .tryMap({
                if $0 == .lock || $0 == .disable {
                    throw FarmLandBikeKit.Error.deviceNotUnlocked
                } else {
                    let name: ParameterData.Apple.Name = .INTEGRATED_HMI_ACCESS
                    try self.readParameter(name: name.rawValue, part: .HMI)
                    return name
                }
            })
            .flatMap({ name in
                self.parameterDataPublisher
                    .filter({ $0.name == name.rawValue })
                    .map({ $0.dividedParameters })
                    .map({ $0?.map({ $0.value as? Int }) })
                    .map({ $0?.compactMap({ $0 }) })
                    .eraseToAnyPublisher()
            })
            .eraseToAnyPublisher()
    }
    
    public func setHmiPasswordCode(_ passwords: [Int]) -> AnyPublisher<String, Swift.Error> {
        self.screenLockPublisher
            .compactMap({ $0.state })
            .tryMap({
                if $0 == .lock || $0 == .disable {
                    throw FarmLandBikeKit.Error.deviceNotUnlocked
                } else {
                    let name: ParameterData.Apple.Name = .INTEGRATED_HMI_ACCESS
                    try self.writeParameter(name: name.rawValue, part: .HMI, value: passwords)
                    return "\(name.rawValue): (\(passwords))"
                }
            })
            .eraseToAnyPublisher()
    }
    
    public func getHmiErrorLimit() -> AnyPublisher<Int?, Swift.Error> {
        let name: ParameterData.Apple.Name = .HmiErrorLimit
        do {
            try self.readParameter(name: name.rawValue, part: .HMI)
        } catch {
            return Fail<Int?, Swift.Error>(error: error)
                .eraseToAnyPublisher()
        }
        return self.parameterDataPublisher
            .filter({ $0.name == name.rawValue })
            .map({ $0.value as? Int })
            .eraseToAnyPublisher()
    }
    
    public func setHmiErrorLimit(_ limitation: Int) -> AnyPublisher<String, Swift.Error> {
        self.screenLockPublisher
            .compactMap({ $0.state })
            .tryMap({
                if $0 == .lock || $0 == .disable {
                    throw FarmLandBikeKit.Error.deviceNotUnlocked
                } else {
                    let name: ParameterData.Apple.Name = .HmiErrorLimit
                    try self.writeParameter(name: name.rawValue, part: .HMI, value: limitation)
                    return "\(name.rawValue): (\(limitation))"
                }
            })
            .eraseToAnyPublisher()
    }
    
    public func setScreenLockToken(_ token: UUID) -> AnyPublisher<Bool, Swift.Error> {
        self.screenLockPublisher
            .compactMap({ $0.state })
            .first()
            .tryMap({
                if $0 == .lock || $0 == .disable {
                    throw FarmLandBikeKit.Error.deviceNotUnlocked
                } else {
                    let name: ParameterData.Apple.Name = .HmiSvrToken
                    try self.writeParameter(name: name.rawValue, part: .HMI, value: token.toToken)
                }
            })
            .flatMap({ _ in
                self.writingParameterStatePublisher
                    .setFailureType(to: Swift.Error.self)
            })
            .compactMap({ $0?.state })
            .eraseToAnyPublisher()
    }
    
    public func resetScreenAccessControl(_ token: UUID) -> AnyPublisher<Void, Swift.Error> {
        let name: ParameterData.Apple.Name = .HmiSvrToken
        do {
            try self.readParameter(name: name.rawValue, part: .HMI)
        } catch {
            return Fail<Void, Swift.Error>(error: error)
                .eraseToAnyPublisher()
        }
        return self.parameterDataPublisher
            .filter({ $0.name == name.rawValue && $0.partType == .HMI })
            .prefix(1)
            .tryMap({
                guard let uuid: String = $0.value as? String else {
                    throw FarmLandBikeKit.Error.screenLockTokenCorrupted
                }
                guard uuid == token.toToken else {
                    throw FarmLandBikeKit.Error.screenLockTokenIsNotAllowed
                }
                try self.coreSDKService.resetScreenAccessControl()
            })
            .eraseToAnyPublisher()
    }
    
    public func checkScreenLockTokenIsValid() -> AnyPublisher<Bool, Swift.Error> {
        let name: ParameterData.Apple.Name = .HmiSvrToken
        do {
            try self.readParameter(name: name.rawValue, part: .HMI)
        } catch {
            return Fail<Bool, Swift.Error>(error: error)
                .eraseToAnyPublisher()
        }
        return self.parameterDataPublisher
            .filter({ $0.name == name.rawValue })
            .first()
            .map({ $0.value })
            .map({
                if let value: String = $0 as? String {
                    let firstSegment: String = .init(value.prefix(8))
                    let secondSegment: String = .init(value.dropFirst(8).prefix(4))
                    let thirdSegment: String = .init(value.dropFirst(12).prefix(4))
                    let fourthSegment: String = .init(value.dropFirst(16).prefix(4))
                    let fifthSegment: String = .init(value.dropFirst(20))
                    let token = "\(firstSegment)-\(secondSegment)-\(thirdSegment)-\(fourthSegment)-\(fifthSegment)"
                    let uuid: UUID? = .init(uuidString: token)
                    return uuid != nil
                } else {
                    return false
                }
            })
            .eraseToAnyPublisher()
    }
    
    public func getTimeToSleep() -> AnyPublisher<Int, Swift.Error> {
        let name: ParameterData.Apple.Name = .METER_SLEEP_TIME
        do {
            try self.readParameter(name: name.rawValue, part: .HMI)
        } catch {
            return Fail<Int, Swift.Error>(error: error)
                .eraseToAnyPublisher()
        }
        return self.parameterDataPublisher
            .filter({ $0.name == name.rawValue })
            .filter({ $0.partType == .HMI })
            .compactMap({ $0.value as? Int })
            .first()
            .eraseToAnyPublisher()
    }
    
    public func setTimeToSleep(_ second: Int) -> AnyPublisher<Bool, Swift.Error> {
        guard second <= 10800, second >= 10 else {
            let timeinterval: TimeInterval = .init(second)
            let error: FarmLandBikeKit.Error = .sleepTimeOutOfBounds(timeinterval)
            return Fail<Bool, Swift.Error>(error: error)
                .eraseToAnyPublisher()
        }
        let name: ParameterData.Apple.Name = .METER_SLEEP_TIME
        do {
            try self.writeParameter(name: name.rawValue, part: .HMI, value: second)
        } catch {
            return Fail<Bool, Swift.Error>(error: error)
                .eraseToAnyPublisher()
        }
        return self.writingParameterStatePublisher
            .compactMap({ $0 })
            .filter({
                do {
                    let parameterData: ParameterData = try self.parameterDataRepository.findParameterData(type: $0.device, bank: $0.bank, address: $0.address, length: $0.length)
                    return parameterData.name == name.rawValue
                } catch {
                    return false
                }
            })
            .first()
            .map({ $0.state })
            .setFailureType(to: Swift.Error.self)
            .eraseToAnyPublisher()
    }
    
    public func appleDeviceInfoPublisher(throttle milliseconds: Int = 0) -> AnyPublisher<Apple_Info_st, Swift.Error> {
        self.deviceInfoPublisher(throttle: milliseconds)
            .tryCompactMap({ try $0.deviceInfo?.asAppleDeviceInfo() })
            .eraseToAnyPublisher()
    }
}
