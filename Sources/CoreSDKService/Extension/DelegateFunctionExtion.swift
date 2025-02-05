//
//  File.swift
//  
//
//  Created by Yves Tsai on 2024/2/26.
//

import Foundation

import CoreSDKSourceCode

protocol DelegateFunction {
    func readParameters(return_state: RouterType, target_device: SDKDeviceType_e, addr: UInt16, leng: UInt16, bank_index: UInt8, callback: fpCallback_ReadParameters?) throws -> Int32
    
    func writeStringParameters(router: RouterType, target_device: SDKDeviceType_e, addr: UInt16, leng: UInt16, bank_index: UInt8, callback: fpCallback_WriteParameters?) throws -> Int32
    
    func writeIntParameters(router: RouterType, target_device: SDKDeviceType_e, addr: UInt16, leng: UInt16, bank_index: UInt8, callback: fpCallback_WriteParameters?) throws -> Int32
    
    func writeIntArrayParameters(router: RouterType, target_device: SDKDeviceType_e, addr: UInt16, leng: UInt16, bank_index: UInt8, dividedParameters: [ParameterData], callback: fpCallback_WriteParameters?) throws -> Int32
    
    func restartDevice(router: RouterType, target_device: SDKDeviceType_e, callback: fpCallback_NoParamReturn?) throws -> Int32
    
    func clearTripInfo(router: RouterType, callback: fpCallback_NoParamReturn?) throws -> Int32
    
    func resetParameters(router: RouterType, target_device: SDKDeviceType_e, bank_index: UInt8, callback: fpCallback_ResetParameters?) throws -> Int32
    
    func configSystemTime(router: RouterType, target_device: SDKDeviceType_e?, unix_time: UInt64, callback: fpCallback_NoParamReturn?) throws -> Int32
    
    func lightControl(router: RouterType, parts: light_control_parts, on_off: Bool, callback: fpCallback_NoParamReturn?) throws -> Int32
    
    func upgradeFirmware(router: RouterType, target_device: SDKDeviceType_e, device_MID: UnsafeMutablePointer<UInt8>?, data: UnsafeMutablePointer<UInt8>?, data_size: UInt32, upgrade_msg_callback: UpgradeStateMsg_p?, callback: fpCallback_NoParamReturn?) throws -> Int32
    
    func getELock(router: RouterType, callback: fpCallback_GetELock_DEV?) throws -> Int32
    
    func setELock(router: RouterType, release: Bool, unlocked: Bool, callback: fpCallback_NoParamReturn?) throws -> Int32
    
    func setAssistLevel(router: RouterType, set_level: UInt8, callback: fpCallback_NoParamReturn?) throws -> Int32
    
    func setScreenAccessControl(router: RouterType, device: SDKDeviceType_e, action: Int32, password: UnsafeMutablePointer<UInt8>?, callback: fpCallback_SetScreenAccessCtrl?) throws -> Int32
    
    func resetScreenAccessControl(router: RouterType, device: SDKDeviceType_e, callback: fpCallback_ResetScreenAccessCtrl?) throws -> Int32
}

extension Apple_DelegateFuncDefine_T: DelegateFunction {
    func readParameters(return_state: RouterType, target_device: SDKDeviceType_e, addr: UInt16, leng: UInt16, bank_index: UInt8, callback: fpCallback_ReadParameters?) throws -> Int32 {
        self.ReadParameters(return_state, target_device, addr, leng, bank_index, callback)
    }
    
    func writeStringParameters(router: RouterType, target_device: SDKDeviceType_e, addr: UInt16, leng: UInt16, bank_index: UInt8, callback: fpCallback_WriteParameters?) throws -> Int32 {
        var result: Int32!
        withUnsafePointer(to: &CoreSDKService.writingStringData) { pointer in
            result = self.WriteParameters(router, target_device, addr, leng, bank_index, pointer.pointee, callback)
        }
        return result
    }
    
    func writeIntParameters(router: RouterType, target_device: SDKDeviceType_e, addr: UInt16, leng: UInt16, bank_index: UInt8, callback: fpCallback_WriteParameters?) throws -> Int32 {
        let unsafeMutableRawPointer = UnsafeMutableRawPointer.allocate(byteCount: MemoryLayout<Int32>.stride * 2, alignment: MemoryLayout<Int>.alignment)
        unsafeMutableRawPointer.storeBytes(of: CoreSDKService.writingIntData, as: Int.self)
        return self.WriteParameters(SDK_ROUTER_BLE, target_device, addr, leng, bank_index, unsafeMutableRawPointer, callback)
    }
    
    /**
     寫入多個 Int 參數的數組至設備。

     - parameter router: 目標路由
     - parameter target_device: 目標設備
     - parameter addr: 寫入的起始位址
     - parameter leng: 總長度 (以 byte 計算)
     - parameter bank_index: 索引
     - parameter callback: 寫入操作完成後的回調
     - Throws: 若處理過程中發生錯誤，將拋出錯誤
     - Returns: 操作的結果狀態碼
     */
    func writeIntArrayParameters(
        router: RouterType,
        target_device: SDKDeviceType_e,
        addr: UInt16,
        leng: UInt16,
        bank_index: UInt8,
        dividedParameters: [ParameterData],
        callback: fpCallback_WriteParameters?
    ) throws -> Int32 {
        let buffer: UnsafeMutableRawPointer = .allocate(byteCount: .init(leng), alignment: MemoryLayout<Int32>.alignment)
        
        defer {
            // 檢查 buffer 中的內容是否正確
            let rawBufferPointer: UnsafeRawBufferPointer = .init(start: buffer, count: Int(leng))
            let bufferContent: [UnsafeRawBufferPointer.Element] = rawBufferPointer.map({ $0 })
#if DEBUG
            print("檢查 buffer 內容: \(bufferContent)")
#endif
            buffer.deallocate()
        }
        
        guard CoreSDKService.writingIntArrayData.count == dividedParameters.count else {
            throw NSError(domain: "WriteIntArrayParametersError", code: 3, userInfo: [NSLocalizedDescriptionKey: "Memory mismatch detected"])
        }
        
        // 寫入數據
        var offset = 0
        for (index, value) in CoreSDKService.writingIntArrayData.enumerated() {
            let length: Int = .init(dividedParameters[index].length)

            print("正在處理第 \(index + 1) 筆數據，值：\(value)，長度：\(length) bytes，當前 offset: \(offset)")

            if offset + length > .init(leng) {
                print("錯誤：當前 offset (\(offset)) 超過總內存大小 \(leng)！")
                throw NSError(domain: "WriteIntArrayParametersError", code: 4, userInfo: [NSLocalizedDescriptionKey: "Memory overflow detected"])
            }

            // 寫入數據
            buffer.storeBytes(of: value, toByteOffset: offset, as: type(of: value))

            offset += length
            print("更新後的 offset: \(offset)")
        }
        
        // 進行寫入操作
        print("數據寫入完成，開始進行 WriteParameters 操作")
        
        return self.WriteParameters(router, target_device, addr, leng, bank_index, buffer.assumingMemoryBound(to: Int32.self), callback)
    }
    
    func restartDevice(router: RouterType, target_device: SDKDeviceType_e, callback: fpCallback_NoParamReturn?) throws -> Int32 {
        self.RestartDevice(router, target_device, callback)
    }
    
    func clearTripInfo(router: RouterType, callback: fpCallback_NoParamReturn?) throws -> Int32 {
        self.ClearTripInfo(router, callback)
    }
    
    func resetParameters(router: RouterType, target_device: SDKDeviceType_e, bank_index: UInt8, callback: fpCallback_ResetParameters?) throws -> Int32 {
        self.ResetParameters(router, target_device, bank_index, callback)
    }
    
    func configSystemTime(router: RouterType, target_device: SDKDeviceType_e?, unix_time: UInt64, callback: fpCallback_NoParamReturn?) throws -> Int32 {
        guard let target_device: SDKDeviceType_e else {
            throw Tenant.Error.delegateFunctionArgMissing(["target_device"])
        }
        return self.ConfigSysTime(router, target_device, unix_time, callback)
    }
    
    func lightControl(router: RouterType, parts: light_control_parts, on_off: Bool, callback: fpCallback_NoParamReturn?) throws -> Int32 {
        self.LightControl(router, parts, on_off, callback)
    }
    
    func upgradeFirmware(router: RouterType, target_device: SDKDeviceType_e, device_MID: UnsafeMutablePointer<UInt8>?, data: UnsafeMutablePointer<UInt8>?, data_size: UInt32, upgrade_msg_callback: UpgradeStateMsg_p?, callback: fpCallback_NoParamReturn?) throws -> Int32 {
        self.UpgradeFirmware(router, target_device, device_MID, data, data_size, upgrade_msg_callback, callback)
    }
    
    func getELock(router: RouterType, callback: fpCallback_GetELock_DEV?) throws -> Int32 {
        self.GetELock_DEV(router, callback)
    }
    
    func setELock(router: RouterType, release: Bool, unlocked: Bool, callback: fpCallback_NoParamReturn?) throws -> Int32{
        self.SetELock_DEV(router, release, unlocked, callback)
    }
    
    func setAssistLevel(router: RouterType, set_level: UInt8, callback: fpCallback_NoParamReturn?) throws -> Int32 {
        self.SetAssistLV(router, set_level, callback)
    }
    
    func setScreenAccessControl(router: RouterType, device: SDKDeviceType_e, action: Int32, password: UnsafeMutablePointer<UInt8>?, callback: fpCallback_SetScreenAccessCtrl?) throws -> Int32 {
        self.SetScreenAccessCtrl(router, device, action, password, callback)
    }
    
    func resetScreenAccessControl(router: RouterType, device: SDKDeviceType_e, callback: fpCallback_ResetScreenAccessCtrl?) throws -> Int32 {
        self.ResetScreenAccessCtrl(router, device, callback)
    }
}

extension Orange_DelegateFuncDefine_T: DelegateFunction {
    func readParameters(return_state: RouterType, target_device: SDKDeviceType_e, addr: UInt16, leng: UInt16, bank_index: UInt8, callback: fpCallback_ReadParameters?) throws -> Int32 {
        self.ReadParameters(return_state, target_device, addr, leng, bank_index, callback)
    }
    
    func writeStringParameters(router: RouterType, target_device: SDKDeviceType_e, addr: UInt16, leng: UInt16, bank_index: UInt8, callback: fpCallback_WriteParameters?) throws -> Int32 {
        var result: Int32!
        withUnsafePointer(to: &CoreSDKService.writingStringData) { pointer in
            result = self.WriteParameters(router, target_device, addr, leng, bank_index, pointer.pointee, callback)
        }
        return result
    }
    
    func writeIntParameters(router: RouterType, target_device: SDKDeviceType_e, addr: UInt16, leng: UInt16, bank_index: UInt8, callback: fpCallback_WriteParameters?) throws -> Int32 {
        let unsafeMutableRawPointer = UnsafeMutableRawPointer.allocate(byteCount: MemoryLayout<Int32>.stride * 2, alignment: MemoryLayout<Int>.alignment)
        unsafeMutableRawPointer.storeBytes(of: CoreSDKService.writingIntData, as: Int.self)
        return self.WriteParameters(SDK_ROUTER_BLE, target_device, addr, leng, bank_index, unsafeMutableRawPointer, callback)
    }
    
    /**
     寫入多個 UInt8 整數參數至目標設備的指定記憶體位置。

     - parameter router: 用來進行通訊的路由類型。
     - parameter target_device: 目標設備的類型。
     - parameter addr: 寫入數據的起始地址。
     - parameter leng: 數據的總長度。
     - parameter bank_index: 銀行索引，用於選擇特定的存儲區塊。
     - parameter callback: 寫入操作完成後的回調函數。
     - Throws: 若數據或內存處理過程中發生錯誤，將拋出錯誤。
     - Returns: 操作的結果狀態碼。
     */
    func writeIntArrayParameters(
        router: RouterType,
        target_device: SDKDeviceType_e,
        addr: UInt16,
        leng: UInt16,
        bank_index: UInt8,
        dividedParameters: [ParameterData],
        callback: fpCallback_WriteParameters?
    ) throws -> Int32 {

        // 確保 CoreSDKService.writingIntArrayData 有數據可以寫入，否則拋出錯誤。
        guard !CoreSDKService.writingIntArrayData.isEmpty else {
            throw NSError(domain: "WriteIntArrayParametersError", code: 5, userInfo: [NSLocalizedDescriptionKey: "No data to write"])
        }

        // 根據 CoreSDKService.writingIntArrayData 的數量計算所需內存大小，每個數據為 1 byte。
        let totalBytes = MemoryLayout<UInt8>.stride * CoreSDKService.writingIntArrayData.count
        print("總共需要分配的內存長度：\(totalBytes) bytes")

        // 分配足夠的內存空間以存儲所有數據。
        let buffer = UnsafeMutableRawPointer.allocate(byteCount: totalBytes, alignment: MemoryLayout<UInt8>.alignment)
        defer {
            buffer.deallocate()  // 確保函式結束時釋放內存以避免內存洩漏。
        }

        // 用來追蹤寫入數據的內存偏移量。
        var offset = 0

        // 將數據逐個寫入 buffer 中，每次寫入 1 個 byte。
        for (index, value) in CoreSDKService.writingIntArrayData.enumerated() {
            let length = MemoryLayout<UInt8>.stride  // 每次只寫入 1 byte
            
            print("正在處理第 \(index + 1) 筆數據，值：\(value)，長度：\(length) bytes，當前 offset: \(offset)")

            // 將 UInt8 類型的數據寫入對應的內存偏移量。
            buffer.storeBytes(of: UInt8(value), toByteOffset: offset, as: UInt8.self)
            offset += length

            print("更新後的 offset: \(offset)")
            
            // 檢查是否出現內存溢出情況，若發現則拋出錯誤。
            if offset > totalBytes {
                print("錯誤：當前 offset (\(offset)) 超過總內存大小 \(totalBytes)！")
                throw NSError(domain: "WriteIntArrayParametersError", code: 4, userInfo: [NSLocalizedDescriptionKey: "Memory overflow detected"])
            }
        }
        
        // 將填充好的數據 buffer 寫入設備的指定記憶體區域。
        print("數據寫入完成，開始進行 WriteParameters 操作")
        return self.WriteParameters(router, target_device, addr, UInt16(totalBytes), bank_index, buffer.assumingMemoryBound(to: UInt8.self), callback)
    }
    
    func restartDevice(router: RouterType, target_device: SDKDeviceType_e, callback: fpCallback_NoParamReturn?) throws -> Int32 {
        throw Tenant.Error.delegateFunctionNotExist(#function)
    }
    
    func clearTripInfo(router: RouterType, callback: fpCallback_NoParamReturn?) throws -> Int32 {
        throw Tenant.Error.delegateFunctionNotExist(#function)
    }
    
    func resetParameters(router: RouterType, target_device: SDKDeviceType_e, bank_index: UInt8, callback: fpCallback_ResetParameters?) throws -> Int32 {
        throw Tenant.Error.delegateFunctionNotExist(#function)
    }
    
    func configSystemTime(router: RouterType, target_device: SDKDeviceType_e?, unix_time: UInt64, callback: fpCallback_NoParamReturn?) throws -> Int32 {
        self.ConfigSysTime(router, unix_time, callback)
    }
    
    func lightControl(router: RouterType, parts: light_control_parts, on_off: Bool, callback: fpCallback_NoParamReturn?) throws -> Int32 {
        throw Tenant.Error.delegateFunctionNotExist(#function)
    }

    func upgradeFirmware(router: RouterType, target_device: SDKDeviceType_e, device_MID: UnsafeMutablePointer<UInt8>?, data: UnsafeMutablePointer<UInt8>?, data_size: UInt32, upgrade_msg_callback: UpgradeStateMsg_p?, callback: fpCallback_NoParamReturn?) throws -> Int32 {
        self.UpgradeFirmware(router, target_device, device_MID, data, data_size, upgrade_msg_callback, callback)
    }
    
    func getELock(router: RouterType, callback: fpCallback_GetELock_DEV?) throws -> Int32 {
        throw Tenant.Error.delegateFunctionNotExist(#function)
    }
    
    func setELock(router: RouterType, release: Bool, unlocked: Bool, callback: fpCallback_NoParamReturn?) throws -> Int32 {
        throw Tenant.Error.delegateFunctionNotExist(#function)
    }
    
    func setAssistLevel(router: RouterType, set_level: UInt8, callback: fpCallback_NoParamReturn?) throws -> Int32 {
        self.ConfigAssistLv(router, set_level, callback)
    }
    
    func setScreenAccessControl(router: RouterType, device: SDKDeviceType_e, action: Int32, password: UnsafeMutablePointer<UInt8>?, callback: fpCallback_SetScreenAccessCtrl?) throws -> Int32 {
        throw Tenant.Error.delegateFunctionNotExist(#function)
    }
    
    func resetScreenAccessControl(router: RouterType, device: SDKDeviceType_e, callback: fpCallback_ResetScreenAccessCtrl?) throws -> Int32 {
        throw Tenant.Error.delegateFunctionNotExist(#function)
    }
}

extension Orange_DelegateFuncDefine_T {
    @available(*, deprecated, message: "據說(2024.6.19)底層是空實作，沒作用的。")
    func resetDeviceParam(router: RouterType, callback: fpCallback_NoParamReturn?) throws -> Int32 {
        self.ResetDeviceParam(router, callback)
    }
    
    func setBikeStatus(router: RouterType, set_status: ORANGE_BIKE_STATUS_E, callback: fpCallback_NoParamReturn?) throws -> Int32 {
        self.SetBikeStatus(router, set_status, callback)
    }
    
    func setManualTest(router: RouterType, command: ORANGE_MANUAL_TEST_TYPE_E, callback: fpCallback_NoParamReturn?) throws -> Int32 {
        self.SetManualTest(router, command, callback)
    }
    
    func readBatteryInfo(router: RouterType, callback: fpCallback_NoParamReturn?) throws -> Int32 {
        self.ReadBatteryInfo(router, callback)
    }
    
    func resetBikeSettings(router: RouterType, reset_type: UInt8, callback: fpCallback_NoParamReturn?) throws -> Int32 {
        self.ResetBikeSettings(router, reset_type, callback)
    }
}

extension Cherry_DelegateFuncDefine_T: DelegateFunction {
    func readParameters(return_state: RouterType, target_device: SDKDeviceType_e, addr: UInt16, leng: UInt16, bank_index: UInt8, callback: fpCallback_ReadParameters?) throws -> Int32 {
        throw Tenant.Error.delegateFunctionNotExist(#function)
    }
    
    func writeStringParameters(router: RouterType, target_device: SDKDeviceType_e, addr: UInt16, leng: UInt16, bank_index: UInt8, callback: fpCallback_WriteParameters?) throws -> Int32 {
        throw Tenant.Error.delegateFunctionNotExist(#function)
    }
    
    func writeIntParameters(router: RouterType, target_device: SDKDeviceType_e, addr: UInt16, leng: UInt16, bank_index: UInt8, callback: fpCallback_WriteParameters?) throws -> Int32 {
        throw Tenant.Error.delegateFunctionNotExist(#function)
    }
    
    func writeIntArrayParameters(router: RouterType, target_device: SDKDeviceType_e, addr: UInt16, leng: UInt16, bank_index: UInt8, dividedParameters: [ParameterData], callback: fpCallback_WriteParameters?) throws -> Int32 {
        throw Tenant.Error.delegateFunctionNotExist(#function)
    }
    
    func restartDevice(router: RouterType, target_device: SDKDeviceType_e, callback: fpCallback_NoParamReturn?) throws -> Int32 {
        throw Tenant.Error.delegateFunctionNotExist(#function)
    }
    
    func clearTripInfo(router: RouterType, callback: fpCallback_NoParamReturn?) throws -> Int32 {
        throw Tenant.Error.delegateFunctionNotExist(#function)
    }
    
    func resetParameters(router: RouterType, target_device: SDKDeviceType_e, bank_index: UInt8, callback: fpCallback_ResetParameters?) throws -> Int32 {
        throw Tenant.Error.delegateFunctionNotExist(#function)
    }
    
    func configSystemTime(router: RouterType, target_device: SDKDeviceType_e?, unix_time: UInt64, callback: fpCallback_NoParamReturn?) throws -> Int32 {
        throw Tenant.Error.delegateFunctionNotExist(#function)
    }
    
    func lightControl(router: RouterType, parts: light_control_parts, on_off: Bool, callback: fpCallback_NoParamReturn?) throws -> Int32 {
        throw Tenant.Error.delegateFunctionNotExist(#function)
    }
    
    func upgradeFirmware(router: RouterType, target_device: SDKDeviceType_e, device_MID: UnsafeMutablePointer<UInt8>?, data: UnsafeMutablePointer<UInt8>?, data_size: UInt32, upgrade_msg_callback: UpgradeStateMsg_p?, callback: fpCallback_NoParamReturn?) throws -> Int32 {
        throw Tenant.Error.delegateFunctionNotExist(#function)
    }
    
    func getELock(router: RouterType, callback: fpCallback_GetELock_DEV?) throws -> Int32 {
        throw Tenant.Error.delegateFunctionNotExist(#function)
    }
    
    func setELock(router: RouterType, release: Bool, unlocked: Bool, callback: fpCallback_NoParamReturn?) throws -> Int32 {
        throw Tenant.Error.delegateFunctionNotExist(#function)
    }
    
    func setAssistLevel(router: RouterType, set_level: UInt8, callback: fpCallback_NoParamReturn?) throws -> Int32 {
        throw Tenant.Error.delegateFunctionNotExist(#function)
    }
    
    func setScreenAccessControl(router: RouterType, device: SDKDeviceType_e, action: Int32, password: UnsafeMutablePointer<UInt8>?, callback: fpCallback_SetScreenAccessCtrl?) throws -> Int32 {
        throw Tenant.Error.delegateFunctionNotExist(#function)
    }
    
    func resetScreenAccessControl(router: RouterType, device: SDKDeviceType_e, callback: fpCallback_ResetScreenAccessCtrl?) throws -> Int32 {
        throw Tenant.Error.delegateFunctionNotExist(#function)
    }
}
