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
    
    public func dividIntoMultiParameters(rawData: ReadingRawData) throws -> [ParameterData] {
        guard let parameterDataList: [ParameterData] = self.dividedParameters else {
            throw Self.Error.dividedParametersNotExist
        }

        let firstParameterData: ParameterData = parameterDataList.first!
        let lastParameterData: ParameterData = parameterDataList.last!
        guard lastParameterData.address + lastParameterData.length - firstParameterData.address == rawData.length else {
            throw Self.Error.readParamterWithWrongLength
        }

        var result: [ParameterData] = .init()
        for parameterData in parameterDataList {
            let start: Int = Int(parameterData.address - firstParameterData.address)
            let end: Int = Int(parameterData.address + parameterData.length - 1 - firstParameterData.address)
            let bytes: [UInt8] = Array(rawData.bytes[start...end])
            
            let value = try bytes.convert2Value(type: parameterData.type, length: Int(parameterData.length))
            let element: ParameterData = parameterData
            element.value = value
            DispatchQueue.main.async {
                element.subject.send(value)
            }
            
            result.append(element)
        }
        return result
    }
}
