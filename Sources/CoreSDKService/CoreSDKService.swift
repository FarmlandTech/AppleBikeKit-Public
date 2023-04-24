//
//  CoreSdkService.swift
//  DST
//
//  Created by abe chen on 2022/11/1.
//

import Foundation
import Combine

import CoreSDK

protocol CoreSDKDataSource: AnyObject {
    
    func updateDeviceInfo(deviceInfo: FL_Info_st)
    
    func readParameter(rawData: RawData)
}

public final class CoreSDKService: NSObject {
    
    public enum Error: Swift.Error {
        case readSingleParameterFail
        case accessParameterWithUnexpectedType
        case accessParameterWithNoValue
        case accessParameterWithWrongType
        case writeTextOutOfRange
    }
    
    fileprivate static weak var dataSource: CoreSDKDataSource?
    private static var writingData: [UInt8] = .init()
    
    private typealias UpdateDeviceInfoEvent = @convention(c) (DeviceInformation_T) -> Void
    
    private typealias ReadParameterEvent = @convention(c) (Int32, DeviceType_enum, Optional<UnsafeMutablePointer<UInt8>>, UInt16, UInt16, UInt8) -> Void
    
    private typealias WriteParameterEvent = @convention(c) (Int32) -> Void
    
    private let updateDeviceInfoEvent: UpdateDeviceInfoEvent = { deviceInfo in
        CoreSDKService.dataSource?.updateDeviceInfo(deviceInfo: deviceInfo.FL)
    }
    
    private let readParameterEvent: ReadParameterEvent = { returnState, targetDevice, pointer, address, length, bank in
        
        guard let pointer: UnsafeMutablePointer<UInt8> else { return }
        
        let rawData: RawData = .init(targetDevice: targetDevice,
                                     bank: bank,
                                     address: address,
                                     length: length,
                                     returnState: returnState,
                                     pointer: pointer)
        CoreSDKService.dataSource?.readParameter(rawData: rawData)
    }
    
    private let writeParameterEvent: WriteParameterEvent = { state in
        
    }
    
    public private(set) lazy var deviceInfoSubject: CurrentValueSubject<FL_Info_st?, Never> = {
        .init(nil)
    }()
    
    public private(set) lazy var rawDataSubject: CurrentValueSubject<RawData?, Never> = {
        .init(nil)
    }()
    
    public private(set) lazy var commandPacketSubject: CurrentValueSubject<[UInt8], Never> = {
        .init(.init())
    }()
    
    public private(set) lazy var dataPacketSubject: CurrentValueSubject<[UInt8], Never> = {
        .init(.init())
    }()
    
    public var sdkVersion: String {
        var version: [UInt8] = Mirror(reflecting: self.coreSDKInst.Version)
            .children
            .map({ $0.value as! UInt8 })
        version.removeAll(where: { $0 == 0 })
        return String(describing: String(bytes: version, encoding: .utf8))
    }
    
    public private(set) lazy var parameterDataRepository: ParameterDataRepository = {
        .init()
    }()
    
    private var coreSDKInst = CoreSDKInst_T()
    
    private var timerSubscription: AnyCancellable?
    
    private let outputDataTimer = Timer.publish(every: 0.01, tolerance: 0.5, on: .main, in: .common).autoconnect()
    
    // 產生原始陣列建議 255 長度，丟給 bleSDK 可接受最大長度為 244 (遵從 hmi ble portocol)
    // Write w response
    private var commandPacketOutData: [UInt8] = [UInt8](repeating: 0x00, count: 244)
    private var commandPacketOutDataLeng: UInt32 = 255
    // Write w/o response
    private var dataPacketOutData: [UInt8] = [UInt8](repeating: 0x00, count: 244)
    private var dataPacketOutDataLeng: UInt32 = 255
    
    public override init() {
        super.init()
        Self.dataSource = self
        self.initCoreSDK()
        self.enableSDK()
        print("AppleBikeKit[CoreSdkService]: init")
    }
    
    deinit {
        Self.dataSource = nil
        self.disableSDK()
        print("AppleBikeKit[CoreSdkService]: deinit")
    }
    
    func initCoreSDK() {
        print("AppleBikeKit[InitializingCoreSDK]: \(self.sdkVersion)")
        self.coreSDKInst.InfoUpdateEvent = self.updateDeviceInfoEvent
        FarmLandCoreSDK_Init(&self.coreSDKInst)
    }
    
    func enableSDK() {
        _ = self.coreSDKInst.Enable()
    }
    
    func disableSDK() {
        _ = self.coreSDKInst.Disable()
    }
    
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
            
            // MARK: part 參數讀寫通道
            let commandPacketOutResult = self.coreSDKInst.Method.BLECommandPacket_OUT(&self.commandPacketOutData, &self.commandPacketOutDataLeng)
            // MARK: 接收 sdk 處理後的 bin 檔 data，主要是更新 fw 會使用到
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
    
    public func read(parameter: ParameterData) throws {
        let isCoreSDKCompleteTask: Int32 = self.coreSDKInst.DelegateMethod.ReadParameters(SDK_ROUTER_BLE, parameter.partType.coreType, parameter.address, parameter.length, parameter.bank, self.readParameterEvent)
        guard isCoreSDKCompleteTask == 0 else {
            throw Self.Error.readSingleParameterFail
        }
    }
    
    public func write(parameter: ParameterData) throws {
        if let _ = parameter.type as? String.Type {
            guard let value: Any = parameter.value else {
                throw Self.Error.accessParameterWithNoValue
            }
            guard let parameterValue: String = value as? String else {
                throw Self.Error.accessParameterWithWrongType
            }
            
            Self.writingData = .init(repeating: 0, count: .init(parameter.length))
            for (index, char) in parameterValue.utf8.enumerated() {
                guard index < Self.writingData.count else {
                    throw Self.Error.writeTextOutOfRange
                }
                Self.writingData[index] = char
            }
            withUnsafePointer(to: &Self.writingData) { pointer in
                _ = self.coreSDKInst.DelegateMethod.WriteParameters(SDK_ROUTER_BLE, parameter.partType.coreType, parameter.address, parameter.length, parameter.bank, pointer.pointee, self.writeParameterEvent)
            }
        } else if let _ = parameter.type as? Int.Type {
            guard let value: Any = parameter.value else {
                throw Self.Error.accessParameterWithNoValue
            }
            guard let parameterValue: Int = value as? Int else {
                throw Self.Error.accessParameterWithWrongType
            }
            
            let count = 2
            let stride = MemoryLayout<Int32>.stride
            let alignment = MemoryLayout<Int>.alignment
            let byteCount = stride * count
            
            let unsafeMutableRawPointer = UnsafeMutableRawPointer.allocate(byteCount: byteCount, alignment: alignment)
            unsafeMutableRawPointer.storeBytes(of: parameterValue, as: Int.self)
            
            let isCoreSDKCompleteTask: Int32 = self.coreSDKInst.DelegateMethod.WriteParameters(SDK_ROUTER_BLE, parameter.partType.coreType, parameter.address, parameter.length, parameter.bank, unsafeMutableRawPointer, self.writeParameterEvent)
            guard isCoreSDKCompleteTask == 0 else {
                throw Self.Error.readSingleParameterFail
            }
        } else {
            throw Self.Error.accessParameterWithUnexpectedType
        }
    }
}

extension CoreSDKService: CoreSDKDataSource {
    
    func updateDeviceInfo(deviceInfo: FL_Info_st) {
        self.deviceInfoSubject.send(deviceInfo)
    }
    
    func readParameter(rawData: RawData) {
        self.rawDataSubject.send(rawData)
    }
}
