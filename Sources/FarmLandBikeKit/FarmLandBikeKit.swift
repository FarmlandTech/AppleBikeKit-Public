//
//  FarmLandBikeKit.swift
//  
//
//  Created by Jeff Chiu on 2023/5/21.
//

import Foundation
import Combine

import CoreBLEServiceSourceCode
import AppleBikeKit
import CoreSDKSourceCode
import CoreSDKService

/// 農田應用程式開發套件，常見需求的集成。
open class FarmLandBikeKit: AppleBikeKit {
    
    public enum HMIAccessControl: UInt32 {
        case lock = 0
        case unlock
        case disable
        case unknown
    }
    
    /// 單例。
    public static let sleipnir: FarmLandBikeKit = .init()
    
    enum Error: Swift.Error {
        case DisguiseBatteryHelperIsNil
        case unsupportedLevel
        case deviceInfoUnavailable
        case functionNotExist(String)
        case deviceNotUnlocked
        case screenLockTokenCorrupted
        case screenLockTokenIsNotAllowed
    }
    
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
            case .unknown, .didConnect(_):
                break
            case .didDisconnect(_):  // 清空緩存數據。
                self.connectionMetaReadingHelper.metaSubject.send(.init())
                self.systemTimeUpdateHelper.stateSubject.send(nil)
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
            }
        }).store(in: &self.subscriptions)
        
        // 監聽裝置資訊。
        self.deviceInfoPublisher().sink(receiveValue: { deviceInfo in

        }).store(in: &self.subscriptions)
    }
    
    /**
     執行藍牙連線。
     */
    public func connectBike(_ peripheral: BluetoothPeripheral) {
        self.connect(peripheral)
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
    public func writeMetricSystem(_ isMetricSystem: Bool) throws {
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
    public override func setAssistLevel(_ level: UInt8) throws {
        guard let deviceInfo: DeviceInfo = self.info.deviceInfo else {
            throw FarmLandBikeKit.Error.deviceInfoUnavailable
        }
        
        if FarmLandBikeKit.tenant == .apple || FarmLandBikeKit.tenant == .kiwi {
            let appleDeviceInfo: Apple_Info_st = try deviceInfo.asAppleDeviceInfo()
            guard appleDeviceInfo.support_assist_lv >= UInt32(level) else {
                throw FarmLandBikeKit.Error.unsupportedLevel
            }
        } else if FarmLandBikeKit.tenant == .orange {
            guard 9 >= UInt32(level) else {
                throw FarmLandBikeKit.Error.unsupportedLevel
            }
        } else {
            fatalError("未授權的使用： \(#function)")
        }
        
        try super.setAssistLevel(level)
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
            .filter({ $0.name == name.rawValue })
            .first()
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
}
