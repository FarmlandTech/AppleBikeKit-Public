//
//  File.swift
//  
//
//  Created by Yves Tsai on 2024/3/27.
//

import Foundation

import CoreSDKSourceCode
import CoreSDKService

public protocol ParameterDataSource {
    
    var hmiBank0Parameters: [ParameterData] { get }
    
    var hmiBank1Parameters: [ParameterData] { get }
    
    var hmiBank2Parameters: [ParameterData] { get }
    
    var controllerBank0Parameters: [ParameterData] { get }
    
    var controllerBank1Parameters: [ParameterData] { get }
    
    var controllerBank2Parameters: [ParameterData] { get }
    
    var batteryBank0Parameters: [ParameterData] { get }
    
    var integratedParameters: [ParameterData] { get }
    
    var parameters: [ParameterData] { get }
    
    func asAppleRepository() throws -> AppleParameterDataRepository
    
    func asOrangeRepository() throws -> OrangeParameterDataRepository

    func asCherryRepository() throws -> CherryParameterDataRepository
    
    /**
     透過名稱枚舉查詢部件參數。
     
     - parameter name: 名稱枚舉。
     - Returns: 目標部件的數據模型。
     - Throws: 搜尋的部件尚未定義，則拋出錯誤。
     */
    func findParameterData(name: String, part: CommunicationPartType) throws -> ParameterData
    
    /**
     透過相關資訊查詢部件參數。
     
     - parameter type: 部件參數的分類。
     - parameter bank: 部件參數的分組。
     - parameter address: 部件參數的起始位址。
     - parameter length: 部件參數的長度。
     - Returns: 目標部件的數據模型。
     - Throws: 搜尋的部件尚未定義，則拋出錯誤。
     */
    func findParameterData(type: DeviceType_enum, bank: UInt8, address: UInt16, length: UInt16) throws -> ParameterData
}

extension ParameterDataSource {
    public func findParameterData(name: String, part: CommunicationPartType) throws -> ParameterData {
        let parameterData: ParameterData? = self.parameters.first(where: { $0.name == name && $0.partType == part })
        if let parameterData: ParameterData {
            return parameterData
        } else {
            throw BaseParameterDataRepository.Error.parameterDataNotFoundByName(name)
        }
    }
    
    public func findParameterData(type: DeviceType_enum, bank: UInt8, address: UInt16, length: UInt16) throws -> ParameterData {
        let parameterData: ParameterData? = self.parameters.first {
            $0.partType.coreType == type && $0.bank == bank && $0.address == address && $0.length == length
        }
        if let parameterData: ParameterData {
            return parameterData
        } else {
            throw BaseParameterDataRepository.Error.parameterDataNotFoundByArguments(type, bank, address, length)
        }
    }
}
