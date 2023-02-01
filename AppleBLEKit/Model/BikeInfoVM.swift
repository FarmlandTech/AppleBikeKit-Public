//
//  BikeInfo.swift
//  DST
//
//  Created by abe chen on 2022/11/11.
//

import Foundation
import AppleDevKit

public enum DiagnosisStatus {
    case notChecked
    case pass
    case error
}

public class BikeInfoViewModel: ObservableObject {
    //MARK: bikeInfo from bike
    var tripTimeSec: UInt32?
    var hmiErrorCodesFromBike: [Int]?
    var controllerErrorCodesFromBike: [Int]?
    var batteryErrorCodesFromBike: [Int]?
    //MARK: for auto diagnosis
    @Published public var progressTimer: Timer?
    @Published public var progressValue: Float = 0
    @Published public var hmiStatus: DiagnosisStatus = .notChecked
    @Published public var controllerStatus: DiagnosisStatus = .notChecked
    @Published public var batteryStatus: DiagnosisStatus = .notChecked
    @Published public var hmiErrorToShow: String?
    @Published public var controllerErrorToShow: String?
    @Published public var batteryErrorToShow: String?
    @Published public var autoDiagnosisFinish: Bool = false
    @Published public var isDiagnosing: Bool = false
    
    
    public init() {
        CoreSdkService.sharedInstance.deviceInfoDataDelegate = self
    }
    
    deinit {
        CoreSdkService.sharedInstance.deviceInfoDataDelegate = nil
    }
}

// Diagnosis func
extension BikeInfoViewModel {
    func startDiagnosis() {
        resetDiagnosis()
        self.progressTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.update), userInfo: nil, repeats: true)
        
    }
    
    func resetDiagnosis() {
        progressValue = 0
        hmiStatus = .notChecked
        controllerStatus = .notChecked
        batteryStatus = .notChecked
        hmiErrorToShow = nil
        controllerErrorToShow = nil
        batteryErrorToShow = nil
        autoDiagnosisFinish = false
        isDiagnosing = true
    }
    
    @objc func update() {
        progressValue += 0.01
        print("progress value: \(progressValue)")
        if progressValue == 0.26000002 {
            let errorStatus = checkError(errorCodes: hmiErrorCodesFromBike!)
            if errorStatus.0 == true {
                hmiStatus = .error
                hmiErrorToShow = convertErrorToString(errorCodes: errorStatus.1)
            } else {
                hmiStatus = .pass
            }
        }
        
        if progressValue == 0.5099998 {
            let errorStatus = checkError(errorCodes: controllerErrorCodesFromBike!)
            if errorStatus.0 == true {
                controllerStatus = .error
                controllerErrorToShow = convertErrorToString(errorCodes: errorStatus.1)
            } else {
                controllerStatus = .pass
            }
        }
        
        if progressValue == 0.7599996 {
            let errorStatus = checkError(errorCodes: batteryErrorCodesFromBike!)
            if errorStatus.0 == true {
                batteryStatus = .error
                batteryErrorToShow = convertErrorToString(errorCodes: errorStatus.1)
            } else {
                batteryStatus = .pass
            }
        }
        
        if progressValue == 1.0499994 {
            self.progressTimer?.invalidate()
            autoDiagnosisFinish = true
            isDiagnosing = false
        }
    }
    
    func checkError(errorCodes: [Int]) -> (Bool, [Int]) {
        let codes = errorCodes.filter{ $0 != 0 }
        var isError: Bool = false
        if !codes.isEmpty {
            isError = true
        }
        //print("checkerror: \(codes) and \(isError)")
        return (isError, codes)
    }
    
    func convertErrorToString(errorCodes: [Int]) -> String {
        var errorString: String = ""
        if errorCodes.isEmpty {
            return errorString
        } else {
            let stringOfErrors = errorCodes.map { String($0) }
            errorString = stringOfErrors.joined(separator: ", ")
            return errorString
        }
        
    }
}

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}

extension BikeInfoViewModel: CoreSdkDataDelegate {
    func updateDeviceInfo(deviceInfo: FL_Info_st) {
        let hmiErrorListByteArray = withUnsafeBytes(of: deviceInfo.HMI_error_list) { buf in
            [UInt8](buf)
        }.chunked(into: 4)
        
        let controllerErrorListByteArray = withUnsafeBytes(of: deviceInfo.controller_error_list) { buf in
            [UInt8](buf)
        }.chunked(into: 4)
        
        let batteryErrorListByteArray = withUnsafeBytes(of: deviceInfo.battery_error_list) { buf in
            [UInt8](buf)
        }.chunked(into: 4)
        
        let hmiErrorCodes = CoreSdkService.sharedInstance.convertErrorList(errorList: hmiErrorListByteArray)
        let controllerErrorCodes = CoreSdkService.sharedInstance.convertErrorList(errorList: controllerErrorListByteArray)
        let batteryErrorCodes = CoreSdkService.sharedInstance.convertErrorList(errorList: batteryErrorListByteArray)
        
        DispatchQueue.main.async {
            self.tripTimeSec = deviceInfo.trip_time_sec
            self.hmiErrorCodesFromBike = hmiErrorCodes
            self.controllerErrorCodesFromBike = controllerErrorCodes
            self.batteryErrorCodesFromBike = batteryErrorCodes
        }
    }
}
