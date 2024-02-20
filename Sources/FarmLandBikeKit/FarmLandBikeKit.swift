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

/// 農田應用程式開發套件，常見需求的集成。
final public class FarmLandBikeKit: AppleBikeKit {
    
    /// 單例。
    public static let sleipnir: FarmLandBikeKit = .init()
    
    enum Error: Swift.Error {
        case DisguiseBatteryHelperIsNil
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
        self.parameterDataPubisher
            .filter({ $0.name == .INTEGRATED_MILEAGE_RECORD })
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
                    try self.systemTimeUpdateHelper.doTask()
                } catch {
                    // TODO: 錯誤處理？
                    assertionFailure("\(error)")
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
        try self.readParameter(name: .INTEGRATED_MILEAGE_RECORD)
    }
    
    /**
     控制車燈開關。
     
     - parameter part: 前燈或後燈。
     - parameter isOn: 開或關。
     - Throws: CoreSDK 執行失敗，或部件版本並未支持此功能。
     */
    public override func lightControl(part: light_control_parts = LIGHT_CONTROL_FRONT, isOn: Bool) throws {
        try self.checkVersion(part: .controller, version: "0.0.22")
        try self.checkVersion(part: .hmi, version: "0.0.20")
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
}
