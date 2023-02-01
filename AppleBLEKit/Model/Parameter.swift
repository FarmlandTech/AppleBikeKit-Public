//
//  Parameters.swift
//  DST
//
//  Created by abe chen on 2022/11/1.
//

import Foundation
import AppleDevKit
import BikeBLEKit

// 有通訊 part
enum CommPartType: Int {
    case HMI = 1
    case Controller = 2
    case MainBatt = 3
    case SubBatt1 = 4
    case SubBatt2 = 5
    case Display = 6
    case IOT = 7
    case EDerailleur = 8
    case ELock = 9
    case Dongle = 10
    case Unknown = 255
}

public enum ConnectStatus {
    case connecting
    case rescueDFU // 救援 dfu
    case updateFW // 更新 FW
    case success
    case fail
}

func getCommPartTypeRawValue(is commpartType: CommPartType) -> Int {
    return commpartType.rawValue
}

struct ParameterData {
    var name: String
    var partType: CommPartType
    var bank: UInt8
    var address: UInt16
    var length: UInt16
    var type: String
    var value: String?
}

// 全局 part state 來存放 data
public class PartDataViewModel: ObservableObject {
    let device: BluetoothPeripheral
    let networkManager = NetworkManager()
    let userDefaults = UserDefaults.standard
    var currentBikeSmidData: SmidData? = nil
    var currentBikeSsnData: SsnData? = nil
    
    @Published public var connectStatus: ConnectStatus = .connecting
    @Published var connectErrorMessage: String = ""
    @Published var currentReadParameterIndex: Int = 0
    
    @Published var parameters: [ParameterData] = [  
        //MARK: Hmi parameters
        
        ParameterData(name: "HmiSMID", partType: .HMI, bank: 0, address: 0, length: 15, type: "string", value: nil),
        ParameterData(name: "HmiDMID", partType: .HMI, bank: 0, address: 15, length: 17, type: "string", value: nil),
        ParameterData(name: "HmiSSN", partType: .HMI, bank: 0, address: 32, length: 32, type: "string", value: nil),
        ParameterData(name: "HmiDSN", partType: .HMI, bank: 0, address: 64, length: 32, type: "string", value: nil),
        ParameterData(name: "HmiFrameNo", partType: .HMI, bank: 0, address: 96, length: 32, type: "string", value: nil),
        ParameterData(name: "HmiDFU", partType: .HMI, bank: 0, address: 1023, length: 1, type: "int", value: nil),
        ParameterData(name: "HmiFwVersion", partType: .HMI, bank: 0, address: 134, length: 6, type: "string", value: nil),
        ParameterData(name: "HmiMileageUnit", partType: .HMI, bank: 2, address: 153, length: 1, type: "bool", value: nil),
        ParameterData(name: "HmiAvgSpeed", partType: .HMI, bank: 2, address: 8, length: 2, type: "int", value: nil),
        ParameterData(name: "HmiMaxSpeed", partType: .HMI, bank: 2, address: 10, length: 2, type: "int", value: nil),
        
        //MARK: Controller parameters
        ParameterData(name: "ControllerSMID", partType: .Controller, bank: 0, address: 0, length: 15, type: "string", value: nil),
        ParameterData(name: "ControllerDMID", partType: .Controller, bank: 0, address: 15, length: 17, type: "string", value: nil),
        ParameterData(name: "ControllerSSN", partType: .Controller, bank: 0, address: 32, length: 32, type: "string", value: nil),
        ParameterData(name: "ControllerDSN", partType: .Controller, bank: 0, address: 64, length: 32, type: "string", value: nil),
        ParameterData(name: "ControllerFrameNo", partType: .Controller, bank: 0, address: 96, length: 32, type: "string", value: nil),
        ParameterData(name: "ControllerDFU", partType: .Controller, bank: 0, address: 1023, length: 1, type: "int", value: nil),
        ParameterData(name: "ControllerFwVersion", partType: .Controller, bank: 0, address: 134, length: 6, type: "string", value: nil),
        ParameterData(name: "ControllerTotalODO", partType: .Controller, bank: 1, address: 217, length: 4, type: "int", value: nil),
        ParameterData(name: "ControllerSpeedLimit", partType: .Controller, bank: 1, address: 345, length: 2, type: "int", value: nil),
        ParameterData(name: "ControllerTireSize", partType: .Controller, bank: 1, address: 347, length: 2, type: "int", value: nil),
        
        //MARK: Battery parameters
        ParameterData(name: "BattSMID", partType: .MainBatt, bank: 0, address: 0, length: 15, type: "string", value: nil),
        ParameterData(name: "BattDMID", partType: .MainBatt, bank: 0, address: 15, length: 17, type: "string", value: nil),
        ParameterData(name: "BattSSN", partType: .MainBatt, bank: 0, address: 32, length: 32, type: "string", value: nil),
        ParameterData(name: "BattDSN", partType: .MainBatt, bank: 0, address: 64, length: 32, type: "string", value: nil),
        ParameterData(name: "BattFrameNo", partType: .MainBatt, bank: 0, address: 96, length: 32, type: "string", value: nil),
        ParameterData(name: "BattDFU", partType: .MainBatt, bank: 0, address: 1023, length: 1, type: "int", value: nil),
        ParameterData(name: "BattFwVersion", partType: .MainBatt, bank: 0, address: 134, length: 6, type: "string", value: nil),
    ]
    
    //MARK: Assist Level param
    var assistLevelParameters:[ParameterData] = [
        ParameterData(name: "P_AST_LV1_STR_RANG", partType: .Controller, bank: 2, address: 131, length: 2, type: "int", value: nil),
        ParameterData(name: "P_AST_LV1_STR_ACC", partType: .Controller, bank: 2, address: 175, length: 1, type: "int", value: nil),
        ParameterData(name: "P_AST_LV1_STR_DEC", partType: .Controller, bank: 2, address: 176, length: 1, type: "int", value: nil),
        ParameterData(name: "P_AST_LV2_STR_RANG", partType: .Controller, bank: 2, address: 200, length: 2, type: "int", value: nil),
        ParameterData(name: "P_AST_LV2_STR_ACC", partType: .Controller, bank: 2, address: 208, length: 1, type: "int", value: nil),
        ParameterData(name: "P_AST_LV2_STR_DEC", partType: .Controller, bank: 2, address: 209, length: 1, type: "int", value: nil),
        ParameterData(name: "P_AST_LV3_STR_RANG", partType: .Controller, bank: 2, address: 202, length: 2, type: "int", value: nil),
        ParameterData(name: "P_AST_LV3_STR_ACC", partType: .Controller, bank: 2, address: 210, length: 1, type: "int", value: nil),
        ParameterData(name: "P_AST_LV3_STR_DEC", partType: .Controller, bank: 2, address: 211, length: 1, type: "int", value: nil),
        
        ParameterData(name: "P_LV1_MAX_AST_RATIO", partType: .Controller, bank: 2, address: 133, length: 2, type: "int", value: nil),
        ParameterData(name: "P_LV1_MIN_AST_RATIO", partType: .Controller, bank: 2, address: 135, length: 2, type: "int", value: nil),
        ParameterData(name: "P_LV1_AST_RATIO_STR_SPD", partType: .Controller, bank: 2, address: 137, length: 2, type: "int", value: nil),
        ParameterData(name: "P_LV1_AST_RATIO_END_SPD", partType: .Controller, bank: 2, address: 139, length: 2, type: "int", value: nil),
        ParameterData(name: "P_LV2_MAX_AST_RATIO", partType: .Controller, bank: 2, address: 141, length: 2, type: "int", value: nil),
        ParameterData(name: "P_LV2_MIN_AST_RATIO", partType: .Controller, bank: 2, address: 143, length: 2, type: "int", value: nil),
        ParameterData(name: "P_LV2_AST_RATIO_STR_SPD", partType: .Controller, bank: 2, address: 145, length: 2, type: "int", value: nil),
        ParameterData(name: "P_LV2_AST_RATIO_END_SPD", partType: .Controller, bank: 2, address: 147, length: 2, type: "int", value: nil),
        ParameterData(name: "P_LV3_MAX_AST_RATIO", partType: .Controller, bank: 2, address: 149, length: 2, type: "int", value: nil),
        ParameterData(name: "P_LV3_MIN_AST_RATIO", partType: .Controller, bank: 2, address: 151, length: 2, type: "int", value: nil),
        ParameterData(name: "P_LV3_AST_RATIO_STR_SPD", partType: .Controller, bank: 2, address: 153, length: 2, type: "int", value: nil),
        ParameterData(name: "P_LV3_AST_RATIO_END_SPD", partType: .Controller, bank: 2, address: 155, length: 2, type: "int", value: nil),
        ParameterData(name: "P_AST_LV1_MAX_CUR", partType: .Controller, bank: 2, address: 177, length: 2, type: "int", value: nil),
        ParameterData(name: "P_AST_LV2_MAX_CUR", partType: .Controller, bank: 2, address: 181, length: 2, type: "int", value: nil),
        ParameterData(name: "P_AST_LV3_MAX_CUR", partType: .Controller, bank: 2, address: 185, length: 2, type: "int", value: nil),
        ParameterData(name: "P_AST_LV1_ACC", partType: .Controller, bank: 2, address: 179, length: 1, type: "int", value: nil),
        ParameterData(name: "P_AST_LV1_DEC", partType: .Controller, bank: 2, address: 180, length: 1, type: "int", value: nil),
        ParameterData(name: "P_AST_LV2_ACC", partType: .Controller, bank: 2, address: 183, length: 1, type: "int", value: nil),
        ParameterData(name: "P_AST_LV2_DEC", partType: .Controller, bank: 2, address: 184, length: 1, type: "int", value: nil),
        ParameterData(name: "P_AST_LV3_ACC", partType: .Controller, bank: 2, address: 187, length: 1, type: "int", value: nil),
        ParameterData(name: "P_AST_LV3_DEC", partType: .Controller, bank: 2, address: 188, length: 1, type: "int", value: nil),
        ParameterData(name: "P_AST_OSP_DEC", partType: .Controller, bank: 2, address: 197, length: 1, type: "int", value: nil),
        ParameterData(name: "P_AST_OCP_DEC", partType: .Controller, bank: 2, address: 198, length: 1, type: "int", value: nil),
        ParameterData(name: "P_AST_STOP_DEC", partType: .Controller, bank: 2, address: 199, length: 1, type: "int", value: nil),
    ]
    
    public init(device: BluetoothPeripheral) {
        self.device = device
        print("currentDevice： \(device)")
        CoreSdkService.sharedInstance.paramsDelegate = self
    }
    
    // 用來找到特定 Parameter
    func from(name: String) -> ParameterData? {
        for i in parameters.indices {
            if parameters[i].name == name {
                return parameters[i]
            }
        }
        
        return nil
    }
    
    // 存入 part data value
    func insertValue(partType: CommPartType, bank: UInt8, address: UInt16, length: UInt16, value: Any) {
        for i in parameters.indices {
            if (
                parameters[i].partType == partType &&
                parameters[i].bank == bank &&
                parameters[i].address == address &&
                parameters[i].length == length)
            {
                DispatchQueue.main.async {
                    self.parameters[i].value = "\(value)"
                }
            }
        }
    }
    
    // 讀取 part parameter
    func readParameter(parameter: ParameterData) {
        print("read P \(parameter)")
        var deviceType: SDKDeviceType_e?
        
        switch parameter.partType {
        case .HMI:
            deviceType = SDK_FL_HMI
        case .Controller:
            deviceType = SDK_FL_CONTROLLER
        case .MainBatt:
            deviceType = SDK_FL_MAIN_BATT
        case .SubBatt1:
            deviceType = SDK_FL_SUB_BATT1
        case .SubBatt2:
            deviceType = SDK_FL_SUB_BATT2
        case .Display:
            deviceType = SDK_FL_DISPLAY
        case .IOT:
            deviceType = SDK_FL_IOT
        case .EDerailleur:
            deviceType = SDK_FL_E_DERAILLEUR
        case .ELock:
            deviceType = SDK_FL_E_LOCK
        case .Dongle:
            deviceType = SDK_FL_DONGLE
        case .Unknown:
            deviceType = SDK_UNKNOWN
        }
        
        let returnResult = CoreSdkService.sharedInstance.coreSDKInst.DelegateMethod.ReadParameters(SDK_ROUTER_BLE, deviceType!, parameter.address, parameter.length, parameter.bank, readParameterEvent)
    }
    
    // 讀取 parameter callback，讀取後的結果會從這里傳遞出來，in this call back to notify
    let readParameterEvent: @convention(c) (Int32, DeviceType_enum, Optional<UnsafeMutablePointer<UInt8>>, UInt16, UInt16, UInt8) -> Void = {return_state, target_device, read_buff, addrs, leng, bank_index in
        
        var byteArray: [UInt8] = []
        for index in 0..<leng {
            byteArray.append(read_buff![Int(index)])
        }
        
        //var dataToString = String(decoding: byteArray, as: UTF8.self)
        
        print("return_state: \(return_state), target_device: \(target_device), read_buff: \(byteArray), datauuuuu: \(byteArray)")
        print("[addr: \(addrs), leng: \(leng)]")
        print("bank_index: \(bank_index)")
        
        CoreSdkService.sharedInstance.paramsDelegate?.readParam(rawData: RawData(returnState: return_state, targetDevice: target_device, readBuff: byteArray, addrs: addrs, leng: leng, bank: bank_index))
    }
    
    // 因無法連續讀取參數，所以使用 index 的方式來記錄要讀取的下個參數
    public var readParamsIndex = 0
    
    // 會先從 0 開始讀取
    func readParamSchedule() {
        currentReadParameterIndex = readParamsIndex
        readParameter(parameter: parameters[readParamsIndex])
    }
    
    // 打 api: 001LEBB32220801
    func getClouldBikeData(smid: String, ssn: String, completion: @escaping (Bool) -> Void) {
        let token = userDefaults.string(forKey: "token")
        
//        let dispatchGroup = DispatchGroup()
//        let concurrentQueue1 = DispatchQueue(label: "SerialQueue", attributes: .concurrent)
//
//        dispatchGroup.enter()
//
//        concurrentQueue1.async(group: dispatchGroup) {
//            self.requestSMID(smid: smid, token: token) { result in
//                if !result { completion(false) }
//                else {
//                    print("完成 smidData: \(String(describing: self.currentBikeSmidData))")
//                    dispatchGroup.leave()
//                }
//            }
//        }
//
//        let concurrentQueue2 = DispatchQueue(label: "SerialQueue", attributes: .concurrent)
//
//        concurrentQueue2.async(group: dispatchGroup) {
//            self.requestSSN(ssn: ssn, token: token) { result in
//                if !result { completion(false) }
//                else {
//                    print("完成 ssnData: \(String(describing: self.currentBikeSsnData))")
//                    dispatchGroup.leave()
//                }
//            }
//        }
//
//        dispatchGroup.notify(queue: DispatchQueue.main) {
//            completion(true)
//        }
        
        let concurrentQueue = DispatchQueue(label: "concurrentQueue", attributes: .concurrent)
        let semaphore = DispatchSemaphore(value: 1)
        
        for i in 0..<3 {
            semaphore.wait()
            switch i {
            case 0:
                concurrentQueue.async {
                    self.requestSMID(smid: smid, token: token) { result in
                        if result { semaphore.signal() }
                        else { completion(false) }
                    }
                }
            case 1:
                concurrentQueue.async {
                    self.requestSSN(ssn: ssn, token: token) { result in
                        if result { semaphore.signal() }
                        else { completion(false) }
                    }
                }
            case 2:
                concurrentQueue.async {
                    print("已完成 smidData: \(String(describing: self.currentBikeSmidData))")
                    print("已完成 ssnData: \(String(describing: self.currentBikeSsnData))")
                    completion(true)
                    semaphore.signal()
                }
            default:
                break
            }
        }
    }
    
    func requestSMID(smid: String, token: String?, completion: @escaping (Bool) -> Void) {
        self.networkManager.makeRequest(
            toURLPath: "system/model/detail/\(smid)",
            withContentType: .none,
            withHttpMethod: .get,
            withToken: token
        ) { result in
                if let error = result.error {
                    print("smid api error \(error)")
                    completion(false)
                    return
                }
                
                let decoder = JSONDecoder()
                
                if let errorData = result.errorData {
                    do {
                        let errorResponse  = try decoder.decode(BaseResponse<EmptyData>.self, from: errorData)
                        print("errorResponse: \(errorResponse)")
                    } catch {
                        print("api error: \(error)")
                    }
                    completion(false)
                    return
                }
                
                if let data = result.data {
                    do {
                        let smidResponse = try decoder.decode(BaseResponse<SmidData>.self, from: data)
                        if smidResponse.message == "OK" {
                            print("smidResponse: \(smidResponse)")
                            self.currentBikeSmidData = smidResponse.data
                            print("smidData: \(String(describing: self.currentBikeSmidData))")
                            completion(true)
                        }
                    } catch {
                        print(error)
                        completion(false)
                    }
                    
                }
            }
    }
    
    
    func requestSSN(ssn: String, token: String?, completion: @escaping (Bool) -> Void) {
        self.networkManager.makeRequest(
            toURLPath: "system/detail/\(ssn)",
            withContentType: .none,
            withHttpMethod: .get,
            withToken: token) { result in
                if let error = result.error {
                    print("ssn api error \(error)")
                    completion(false)
                    return
                }
                
                let decoder = JSONDecoder()
                
                if let errorData = result.errorData {
                    do {
                        let errorResponse  = try decoder.decode(BaseResponse<EmptyData>.self, from: errorData)
                        print("errorResponse: \(errorResponse)")
                    } catch {
                        print("api error: \(error)")
                    }
                    completion(false)
                    return
                }
                
                if let data = result.data {
                    do {
                        let ssnResponse = try decoder.decode(BaseResponse<SsnData>.self, from: data)
                        if ssnResponse.message == "OK" {
                            print("ssnResponse: \(ssnResponse)")
                            self.currentBikeSsnData = ssnResponse.data
                            print("ssnData: \(String(describing: self.currentBikeSsnData))")
                            completion(true)
                        }
                    } catch {
                        print(error)
                        completion(false)
                    }
                    
                }
            }
    }
    
    
    @Published var partList: [Part] = []
    func combineDataToPartList(smidData: SmidData, ssnData:SsnData) {
        partList = [
            Part(
                mid: smidData.hmiDmid,
                sn: ssnData.hmiDSN,
                name: "HMI",
                fwVersion: from(name: "HmiFwVersion")?.value ?? "",
                manufactureDate: nil,
                bgIcon: "hmi_bg_icon",
                partIcon: "hmi_icon"
            ),
            Part(
                mid: smidData.controllerDmid,
                sn: ssnData.controllerDSN,
                name: "Controller",
                fwVersion: from(name: "ControllerFwVersion")?.value ?? "",
                manufactureDate: nil,
                bgIcon: "controller_bg_icon",
                partIcon: "controller_icon"
            ),
            Part(
                mid: smidData.batteryDmid,
                sn: ssnData.controllerDSN,
                name: "Battery",
                fwVersion: from(name: "BattFwVersion")?.value ?? "",
                manufactureDate: nil,
                bgIcon: "battery_bg_icon",
                partIcon: "battery_icon"
            ),
            Part(
                mid: smidData.motorDmid,
                sn: ssnData.motorDSN,
                name: "Motor",
                fwVersion: nil,
                manufactureDate: nil,
                bgIcon: "motor_bg_icon",
                partIcon: "motor_icon"
            ),
            Part(
                mid: smidData.torqueSensorDmid,
                sn: ssnData.torqueSensorDSN,
                name: "Torque",
                fwVersion: nil,
                manufactureDate: nil,
                bgIcon: "torque_bg_icon",
                partIcon: "torque_icon"
            ),
            Part(
                mid: smidData.eLockDmid,
                sn: ssnData.eLockDSN,
                name: "E-Lock",
                fwVersion: nil,
                manufactureDate: nil,
                bgIcon: "e-lock_bg_icon",
                partIcon: "e-lock_icon"
            ),
            Part(
                mid: smidData.frontLightDmid,
                sn: ssnData.frontLightDSN,
                name: "Front Light",
                fwVersion: nil,
                manufactureDate: nil,
                bgIcon: "lights_bg_icon",
                partIcon: "lights_icon"
            ),
            Part(
                mid: smidData.rearLightDmid,
                sn: ssnData.rearLightDSN,
                name: "Rear Light",
                fwVersion: nil,
                manufactureDate: nil,
                bgIcon: "lights_bg_icon",
                partIcon: "lights_icon"
            ),
            Part(
                mid: smidData.throttleDmid,
                sn: ssnData.throttleDSN,
                name: "Throttle",
                fwVersion: nil,
                manufactureDate: nil,
                bgIcon: "throttle_bg_icon",
                partIcon: "throttle_icon"
            ),
            Part(
                mid: smidData.displayDmid,
                sn: ssnData.displayDSN,
                name: "Display",
                fwVersion: nil,
                manufactureDate: nil,
                bgIcon: nil,
                partIcon: nil
            ),
            Part(
                mid: smidData.cadenceSensorDmid,
                sn: ssnData.cadenceSensorDSN,
                name: "Cadence",
                fwVersion: nil,
                manufactureDate: nil,
                bgIcon: nil,
                partIcon: nil
            ),
            Part(
                mid: smidData.chargerDmid,
                sn: ssnData.chargerDSN,
                name: "Charger", fwVersion: nil,
                manufactureDate: nil,
                bgIcon: nil,
                partIcon: nil
            ),
            Part(
                mid: smidData.eBrakeDmid,
                sn: ssnData.eBrakeDSN,
                name: "E-Brake",
                fwVersion: nil,
                manufactureDate: nil,
                bgIcon: nil,
                partIcon: nil
            ),
            Part(
                mid: smidData.eFrontDerailleurDmid,
                sn: ssnData.eFrontDerailleurDSN,
                name: "Front Derailleur",
                fwVersion: nil,
                manufactureDate: nil,
                bgIcon: nil,
                partIcon: nil
            ),
            Part(
                mid: smidData.eRearDerailleurDmid,
                sn: ssnData.eRearDerailleurDSN,
                name: "Rear Derailleur",
                fwVersion: nil,
                manufactureDate: nil,
                bgIcon: nil,
                partIcon: nil
            ),
            Part(
                mid: smidData.iotDmid,
                sn: ssnData.iotDSN,
                name: "IoT",
                fwVersion: nil,
                manufactureDate: nil,
                bgIcon: nil,
                partIcon: nil
            ),
            Part(
                mid: smidData.hmiDisplayDmid,
                sn: ssnData.hmiDisplayDSN,
                name: "HMI & Display",
                fwVersion: nil,
                manufactureDate: nil,
                bgIcon: nil,
                partIcon: nil
            ),
            Part(
                mid: smidData.batteryHmiDmid,
                sn: ssnData.batteryHmiDSN,
                name: "HMI & Battery",
                fwVersion: nil,
                manufactureDate: nil,
                bgIcon: nil,
                partIcon: nil
            ),
            Part(
                mid: smidData.batteryControllerDmid,
                sn: ssnData.batteryControllerDSN,
                name: "HMI & Controller",
                fwVersion: nil,
                manufactureDate: nil,
                bgIcon: nil,
                partIcon: nil
            ),
            Part(
                mid: smidData.batteryControllerHmiDmid,
                sn: ssnData.batteryControllerHmiDSN,
                name: "HMI & Controller & Battery",
                fwVersion: nil,
                manufactureDate: nil,
                bgIcon: nil,
                partIcon: nil
            ),
        ]
        
        partList = partList.filter{ $0.mid != nil && $0.sn != nil}
    }
    
    func isLocalBikeValid() {
        let pre = NSPredicate(format: "SELF MATCHES %@", "^[A-Z0-9]+$") // 正則：是否為英數組合
        
        let hmiFrameNo = from(name: "HmiFrameNo")?.value
        let controllerFrameNo = from(name: "ControllerFrameNo")?.value
        let batteryFrameNo = from(name: "BattFrameNo")?.value
        
        // 檢查是否為相同的 bike
        if Set([hmiFrameNo, controllerFrameNo, batteryFrameNo]).count == 1 {
            let hmiDFUCode = from(name: "HmiDFU")?.value    
            let controllerDFUCode = from(name: "ControllerDFU")?.value
            let batteryDFUCode = from(name: "BattDFU")?.value
            let smid = from(name: "HmiSMID")?.value
            let ssn = from(name: "HmiSSN")?.value
            
            if (smid != nil && pre.evaluate(with: smid)) {
                getClouldBikeData(smid: smid!, ssn: ssn!) { success in
                    if (success && self.currentBikeSmidData != nil && self.currentBikeSsnData != nil) {
                        DispatchQueue.main.async {
                            self.combineDataToPartList(smidData: self.currentBikeSmidData!, ssnData: self.currentBikeSsnData!)
                            self.connectStatus = .success
                        }
                    } else {
                        DispatchQueue.main.async {
                            self.connectErrorMessage = "Comparison Error\n Please reconnect."
                            BluetoothService.sharedInstance.disconnect(bluetoothPeripheral: CurrentBleDevice.currentPeripheral!)
                            self.connectStatus = .fail
                        }
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.connectErrorMessage = "SMID cannot be empty"
                    BluetoothService.sharedInstance.disconnect(bluetoothPeripheral: CurrentBleDevice.currentPeripheral!)
                    self.connectStatus = .fail
                }
            }
            
            if hmiDFUCode == "187" || controllerDFUCode == "187" || batteryDFUCode == "187" {
                var partInDFU: [CommPartType] = []
                if hmiDFUCode == "187" {
                    partInDFU.append(.HMI)
                }
                
                if controllerDFUCode == "187" {
                    partInDFU.append(.Controller)
                }
                
                if batteryDFUCode == "187" {
                    partInDFU.append(.MainBatt)
                }
                
                DispatchQueue.main.async {
                    self.connectStatus = .rescueDFU
                }
            }
        } else {
            // frameNo 不同代表有拆別的車的 part，可能做個顯示說現在有不同的 part 在車上\self.connectStatus = .success
            print("This is diff part: \(hmiFrameNo), \(controllerFrameNo), \(batteryFrameNo)")
            BluetoothService.sharedInstance.disconnect(bluetoothPeripheral: CurrentBleDevice.currentPeripheral!)
            DispatchQueue.main.async {
                self.connectErrorMessage = "FrameNumber of parts comparison error\n\nHMI FrameNumber: \(hmiFrameNo ?? "Null")\nController FrameNumber: \(controllerFrameNo ?? "Null")\nBattery FrameNumber: \(batteryFrameNo ?? "Null")"
                self.connectStatus = .fail
            }
        }
    }
    
    // MARK: 進行腳踏車配對比對本地與雲端 SMID, DMID
    public func connectDevice() {
        BluetoothService.sharedInstance.connectedDeviceDelegates.append((device.bluetoothDevice.identifier, self))
        BluetoothService.sharedInstance.connect(bluetoothPeripheral: device)
    }
    
    public func disconnectDevice() {
        BluetoothService.sharedInstance.disconnect(bluetoothPeripheral: device)
    }
}

extension PartDataViewModel: CoreSdkParamsDelegate {
    func readParam(rawData: RawData) {
        //print("listIndex before\(listIndex)")
        // 先解包 data
        unpackData(parameter: parameters[readParamsIndex], rawData: rawData)
        
        // index + 1 後，即可讀取下一個參數
        readParamsIndex += 1
        
        // 讀取間隔為 30 毫秒
        if readParamsIndex < parameters.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.07){
                self.readParamSchedule()
            }
        } else {
            // 若沒下一個參數要讀取，即時 stop readWriteCannel
            print("Stop ReadWriteChannel")
            CoreSdkService.sharedInstance.stopReadWriteChannel()
            NSLog("timeeee")
            // 比對腳踏車是否合規
//            self.isLocalBikeValid()
            NSLog("timeeee")
        }
    }
    
    // 根據 data type 解封包, 並儲存 data 到 parameters 裏
    func unpackData(parameter: ParameterData, rawData: RawData) {
        print("parameter unpack: \(parameter)")
        if parameter.type == "string" {
            let removeZeroByteArray = rawData.readBuff.filter{ $0 != 0 }
            let value = String(decoding: removeZeroByteArray, as: UTF8.self)
            print("unpack data(string): \(parameter.name), \(value), \(rawData.readBuff), \(removeZeroByteArray)")
            insertValue(partType: parameter.partType, bank: rawData.bank, address: rawData.addrs, length: rawData.leng, value: value)
        } else if parameter.type == "int" {
            let value = rawData.readBuff.convert2Int(length: Int(rawData.leng))
            print("unpack data(int): \(parameter.name), \(value)")
            insertValue(partType: parameter.partType, bank: rawData.bank, address: rawData.addrs, length: rawData.leng, value: value)
        } else if parameter.type == "bool" {
            let value = rawData.readBuff.convert2BoolText()
            print("unpack data(bool): \(parameter.name), \(value)")
            insertValue(partType: parameter.partType, bank: rawData.bank, address: rawData.addrs, length: rawData.leng, value: value)
        }
    }
}

extension PartDataViewModel: BluetoothServiceConnectedDeviceDelegate {
    public func connectedDevice(device: BluetoothPeripheral) {
        
    }
    
    public func updateRemoteRssi(rssi: Float) {}
    
    // 找到 ble 的 characteristic 並儲存起來，在讀寫時會使用到
    public func discoveredService() {
        guard let services = device.bluetoothDevice.services else { return }
        
        services.forEach { service in
            service.characteristics?.forEach({ characteristic in
                switch characteristic.uuid.uuidString {
                //MARK: Write
                case "46610010-726D-6C61-6E64-546563685457":
                    CurrentBleDevice.writeCharacteristic = characteristic
                    break
                //MARK: Notify
                case "46610011-726D-6C61-6E64-546563685457":
                    CurrentBleDevice.notifyCharacteristic = characteristic
                    BluetoothService.sharedInstance.setNotifyCharacteristic(bluetoothPeripheral: self.device, bluetoothCharacteristic: characteristic, notify: true)
                    break
                //MARK: Write Without Response
                case "46610020-726D-6C61-6E64-546563685457":
                    CurrentBleDevice.writeWithoutResponseCharacteristic = characteristic
                    break
                default:
                    return
                }
            })
        }
        
        CoreSdkService.sharedInstance.startReadWriteChannel()
        self.readParamSchedule()
    }
}
