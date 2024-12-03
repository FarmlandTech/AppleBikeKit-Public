//
//  CherryParameterDataRepository.swift
//  
//
//  Created by Yves Tsai on 2024/3/27.
//

import Foundation

import CoreSDKService

public class CherryParameterDataRepository: BaseParameterDataRepository, ParameterDataSource {
    
    public let hmiBank0Parameters: [ParameterData] = []
    
    public let hmiBank1Parameters: [ParameterData] = []
    
    public let hmiBank2Parameters: [ParameterData] = []
    
    public let controllerBank0Parameters: [ParameterData] = []
    
    public let controllerBank1Parameters: [ParameterData] = []
    
    public let controllerBank2Parameters: [ParameterData] = []
    
    public let batteryBank0Parameters: [ParameterData] = []
    
    public let integratedParameters: [ParameterData] = []
    
    public let parameters: [ParameterData] = []
    
    public func asAppleRepository() throws -> AppleParameterDataRepository {
        throw BaseParameterDataRepository.Error.wrongType(type(of: self))
    }
    
    public func asOrangeRepository() throws -> OrangeParameterDataRepository {
        throw BaseParameterDataRepository.Error.wrongType(type(of: self))
    }
    
    public func asCherryRepository() throws -> CherryParameterDataRepository {
        self
    }
    
    
}
