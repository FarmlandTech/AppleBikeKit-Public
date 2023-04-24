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
}

public final class CoreSDKService: NSObject {
    
    fileprivate static weak var deviceInfoDataDelegate: CoreSDKDataSource?
       
    private typealias UpdateDeviceInfoEvent = @convention(c) (DeviceInformation_T) -> Void
    
    private let updateDeviceInfoEvent: UpdateDeviceInfoEvent = { deviceInfo in
        CoreSDKService.deviceInfoDataDelegate?.updateDeviceInfo(deviceInfo: deviceInfo.FL)
    }
    
    public private(set) lazy var deviceInfoSubject: CurrentValueSubject<FL_Info_st?, Never> = {
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
    
    // 產生原始陣列建議 255 長度，丟給 bleSDK 可接受最大長度為 244 (遵從 hmi ble portocol)
    // Write w response
    private var commandPacketOutData: [UInt8] = [UInt8](repeating: 0x00, count: 244)
    private var commandPacketOutDataLeng: UInt32 = 255
    // Write w/o response
    private var dataPacketOutData: [UInt8] = [UInt8](repeating: 0x00, count: 244)
    private var dataPacketOutDataLeng: UInt32 = 255
    
    public override init() {
        super.init()
        Self.deviceInfoDataDelegate = self
        self.initCoreSDK()
        self.enableSDK()
        print("AppleBikeKit[CoreSdkService]: init")
    }
    
    deinit {
        Self.deviceInfoDataDelegate = nil
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
                var newDataAry: [UInt8] = []
                for index in 0..<self.commandPacketOutDataLeng {
                    newDataAry.append(self.commandPacketOutData[Int(index)])
                }
                print("O newDataAry: \(newDataAry) \(self.commandPacketOutDataLeng)")
                print("commandPacketData0: \(self.commandPacketOutData)")
                print("commandPacketLeng0: \(self.commandPacketOutDataLeng)")
                
//                if let writeCharacteristic = CurrentBleDevice.writeCharacteristic {
//                    let bluetoothCharacteristic = BluetoothCharacteristic(characteristic: writeCharacteristic)
//                    BluetoothService.sharedInstance.writeCharacteristic(bluetoothCharacteristic: bluetoothCharacteristic, value: newDataAry)
//                }
            }
            
            if dataPacketOutResult == SDK_RETURN_SUCCESS.rawValue {
                print("dataPacketOutResult: Success")
                var newDataAry: [UInt8] = []
                for index in 0..<self.dataPacketOutDataLeng {
                    newDataAry.append(self.dataPacketOutData[Int(index)])
                }
                print("dataPacketOutResult newDataAry: \(newDataAry)")
                
//                if let writeWithoutResponseCharacteristic = CurrentBleDevice.writeWithoutResponseCharacteristic {
//                    let bluetoothCharacteristic = BluetoothCharacteristic(characteristic: writeWithoutResponseCharacteristic)
//                    BluetoothService.sharedInstance.writeCharacteristic(bluetoothCharacteristic: bluetoothCharacteristic, value: newDataAry)
//                }
            }
        })
    }
}

extension CoreSDKService: CoreSDKDataSource {
    
    func updateDeviceInfo(deviceInfo: FL_Info_st) {
        self.deviceInfoSubject.send(deviceInfo)
    }
}
