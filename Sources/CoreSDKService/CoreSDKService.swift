//
//  CoreSdkService.swift
//  DST
//
//  Created by abe chen on 2022/11/1.
//

import Foundation
import CoreSDK

struct RawData {
    var returnState: Int32
    var targetDevice: DeviceType_enum
    var readBuff: [UInt8]
    var addrs: UInt16
    var leng: UInt16
    var bank: UInt8
    
    init(returnState: Int32, targetDevice: DeviceType_enum, readBuff: [UInt8], addrs: UInt16, leng: UInt16, bank: UInt8) {
        self.returnState = returnState
        self.targetDevice = targetDevice
        self.readBuff = readBuff
        self.addrs = addrs
        self.leng = leng
        self.bank = bank
    }
}

// boss
protocol CoreSdkDataDelegate: AnyObject {
    func updateDeviceInfo(deviceInfo: FL_Info_st)
}

protocol CoreSdkParamsDelegate: AnyObject {
    func readParam(rawData: RawData)
}

protocol CoreSdkFirmwareUpgradeDelegate: AnyObject {
    func progressStateMsg(outMessage: String, progressValue: Int32)
    func upgradeFinished(returnState: Int32)
}

protocol CoreSDKServiceEventDelegate: AnyObject {
    func didWriteParameter(state: Int)
    func didRestartDevice(state: Int)
}

enum SdkReturnCode {
    case success
    case timeout
    case invalidAddress
    case invalidSize
    case invalidParam
    case crcFail
    case null
    case noInit
    case noMem
    case alreadyExist
}

public final class CoreSdkService: NSObject {
    
    public static let sharedInstance = CoreSdkService()
    
    weak var deviceInfoDataDelegate: CoreSdkDataDelegate?
    weak var paramsDelegate: CoreSdkParamsDelegate?
    weak var firmwareUpgradeDelegate: CoreSdkFirmwareUpgradeDelegate?
    weak var sdkEventDelegate: CoreSDKServiceEventDelegate?
    
    var coreSDKInst = CoreSDKInst_T()
    var version: String?
    var outPutDataTimer: Timer?
    
    private override init() {
        super.init()
        self.initCoreSDK()
        print("CoreSdkService init")
    }
    
    deinit {
        print("CoreSdkService deinit")
    }
    
    let updateDeviceInfoEvent: @convention(c) (DeviceInformation_T) -> Void = { deviceInfo in
        // MARK: 因為是 update @Published variable，所以要放進主線程去更新
        DispatchQueue.main.async {
            CoreSdkService.sharedInstance.deviceInfoDataDelegate?.updateDeviceInfo(deviceInfo: deviceInfo.FL)
        }
    }
    
    // init CoreSDK
    func initCoreSDK() {
        coreSDKInst.InfoUpdateEvent = updateDeviceInfoEvent
        FarmLandCoreSDK_Init(&coreSDKInst)
        sdkEnable()
        getSdkVersion()
    }
    
    // 取得 SDK 版本號
    func getSdkVersion() {
        var version: [UInt8] = Mirror(reflecting: self.coreSDKInst.Version).children.map({$0.value as! UInt8})
        version.removeAll(where: { $0 == 0 })
        let versionToString = String(describing: String(bytes: version, encoding: .utf8))
        self.version = versionToString
        print("coreSDK version: \(versionToString)")
    }
    
    // 啟用 SDK
    func sdkEnable() {
        let _ = coreSDKInst.Enable()
    }
    
    // 停用 SDK
    func sdkDisable() {
        let _ = coreSDKInst.Disable()
    }
    
    // 處理 Notify 吐回的資料
    func commandPacketIn(dataPacket: [UInt8]) {
        var data: [UInt8] = dataPacket
        let _ = coreSDKInst.Method.BLECommandPacket_IN(&data, UInt32(dataPacket.count))
    }
    
    // 停止讀寫通道，不使用就直接 invalidate timer
    func stopReadWriteChannel() {
        self.outPutDataTimer?.invalidate()
    }
    
    // 開啟讀寫通道，讀寫參數或 DFU 時要先開啟
    func startReadWriteChannel() {
        if let timer = self.outPutDataTimer {
            timer.invalidate()
        }
        
        //MARK: 每 10 毫秒 check 一次
        DispatchQueue.main.async {
            self.outPutDataTimer = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(self.outPutDataHandler), userInfo: nil, repeats: true)
        }
    }
    
    // 產生原始陣列建議 255 長度，丟給 bleSDK 可接受最大長度為 244 (遵從 hmi ble portocol)
    // Write w response
    var commandPacketOutData: [UInt8] = [UInt8](repeating: 0x00, count: 244)
    var commandPacketOutDataLeng: UInt32 = 255
    // Write w/o response
    var dataPacketOutData: [UInt8] = [UInt8](repeating: 0x00, count: 244)
    var dataPacketOutDataLeng: UInt32 = 255
    
    // MARK: CoreSDK 讀寫通道
    @objc func outPutDataHandler() {
        // MARK: part 參數讀寫通道
        let commandPacketOutResult =  self.coreSDKInst.Method.BLECommandPacket_OUT(&self.commandPacketOutData, &self.commandPacketOutDataLeng)
        // MARK: 接收 sdk 處理後的 bin 檔 data，主要是更新 fw 會使用到
        let dataPacketOutResult = self.coreSDKInst.Method.BLEDataPacket_OUT(&self.dataPacketOutData, &self.dataPacketOutDataLeng)
                
        if commandPacketOutResult == SDK_RETURN_SUCCESS.rawValue {
            // 要把處理過的原始封包丟給 BleSDK 去傳給 Hmi
            var newDataAry: [UInt8] = []
            for index in 0..<commandPacketOutDataLeng {
                newDataAry.append(self.commandPacketOutData[Int(index)])
            }
            print("O newDataAry: \(newDataAry) \(self.commandPacketOutDataLeng)")
            print("commandPacketData0: \(self.commandPacketOutData)")
            print("commandPacketLeng0: \(self.commandPacketOutDataLeng)")
            
//            if let writeCharacteristic = CurrentBleDevice.writeCharacteristic {
//                let bluetoothCharacteristic = BluetoothCharacteristic(characteristic: writeCharacteristic)
//                BluetoothService.sharedInstance.writeCharacteristic(bluetoothCharacteristic: bluetoothCharacteristic, value: newDataAry)
//            }
        }
        
        if dataPacketOutResult == SDK_RETURN_SUCCESS.rawValue {
            print("dataPacketOutResult: Success")
            var newDataAry: [UInt8] = []
            for index in 0..<dataPacketOutDataLeng {
                newDataAry.append(self.dataPacketOutData[Int(index)])
            }
            print("dataPacketOutResult newDataAry: \(newDataAry)")
            
//            if let writeWithoutResponseCharacteristic = CurrentBleDevice.writeWithoutResponseCharacteristic {
//                let bluetoothCharacteristic = BluetoothCharacteristic(characteristic: writeWithoutResponseCharacteristic)
//                BluetoothService.sharedInstance.writeCharacteristic(bluetoothCharacteristic: bluetoothCharacteristic, value: newDataAry)
//            }
        }
    }
}
