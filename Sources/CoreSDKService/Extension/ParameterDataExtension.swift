//
//  ParameterDataExtension.swift
//  
//
//  Created by Yves Tsai on 2023/4/21.
//

import Foundation

extension ParameterData {
    
    public enum Error: Swift.Error {
        case dividedParametersNotExist
        case readParamterWithWrongLength
    }
    
    public func dividIntoMultiParameters(rawData: RawData) throws -> [ParameterData] {
        guard var parameterDataList: [ParameterData] = self.dividedParameters else {
            throw Self.Error.dividedParametersNotExist
        }

        let firstParameterData: ParameterData = parameterDataList.first!
        let lastParameterData: ParameterData = parameterDataList.last!
        guard lastParameterData.address + lastParameterData.length - firstParameterData.address == rawData.length else {
            throw Self.Error.readParamterWithWrongLength
        }

        var result: [ParameterData] = .init()
        for parameterData in parameterDataList {
            let start: Int = Int(parameterData.address)
            let end: Int = Int(parameterData.address + parameterData.length - 1)
            let bytes: [UInt8] = Array(rawData.bytes[start...end])
            
            var element: ParameterData = parameterData
            element.value = try bytes.convert2Value(type: parameterData.type, length: Int(parameterData.length))
            
            result.append(element)
        }
        return result
    }
}
