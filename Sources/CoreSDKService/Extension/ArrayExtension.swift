//
//  ArrayExtension.swift
//  
//
//  Created by Yves Tsai on 2023/4/19.
//

import Foundation

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: self.count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}

extension Array where Element == Array<UInt8> {
    var mapBytes: Array<Int> {
        self.map({ UnsafeRawPointer($0).assumingMemoryBound(to: Int.self).pointee.littleEndian })
    }
}

extension Array where Element == UInt8 {
    
    enum Error: Swift.Error {
        case readParamterWithUnexpectedType
    }
    
    public func convert2Value(type: Any, length: Int? = nil) throws -> Any {
        if let _ = type as? String.Type {
            return self.convert2Text()
        } else if let _ = type as? Int.Type, let length: Int {
            let length: Int = .init(length)
            return self.convert2Number(length: length)
        } else if let _ = type as? [UInt8].Type {
            return self.map({
                String($0, radix: 2)
            }).map({
                $0.map({ UInt8(String($0)) ?? 0 })
            }).map({
                var target = Array($0.reversed())
                while target.count < 8 {
                    target.append(0)
                }
                return target
            }).flatMap({ $0 })
        } else {
            throw Self.Error.readParamterWithUnexpectedType
        }
    }
    
    public func convert2Bytes(length: Int) -> Array<UInt8> {
        var bytes: [UInt8] = .init()
        for index in 0..<length {
            bytes.append(self[index])
        }
        return bytes
    }
    
    private func convert2Text() -> String {
        String(decoding: self.filter{ $0 != 0 }, as: UTF8.self)
    }
    
    private func convert2Number(length: Int) -> Int {
        var value: UInt32 = 0
        let data = NSData(bytes: self, length: length)
        data.getBytes(&value, length: length)
        value = UInt32(littleEndian: value)
        return Int(value)
    }
    
    private func convert2BoolText() -> String {
        self.first != 0 ? "1" : "0"
    }
}

extension Array where Element == ParameterData {
    public enum ParameterDataError: Swift.Error {
        case noParameterData2Integrate
        case parametersWithinDifferentPartType
        case parametersWithinDifferentBank
        case parametersMisSequence
    }
    
    public func integratedParameter() throws -> ParameterData {
        // 判斷陣列是否為空。
        guard self.count > 0 else {
            throw Array.ParameterDataError.noParameterData2Integrate
        }
        
        // 判斷陣列元素的部件是否都相同。
        let partTypeArray: Array<CommunicationPartType> = self.map({ $0.partType })
        let partTypeSet: Set<CommunicationPartType> = Set(partTypeArray)
        guard partTypeSet.count == 1 else {
            throw Array.ParameterDataError.parametersWithinDifferentPartType
        }
        
        // 判斷陣列元素的 bank 是否都相同。
        let bankArray: Array<UInt8> = self.map({ $0.bank })
        let bankSet: Set<UInt8> = Set(bankArray)
        guard bankSet.count == 1 else {
            throw Array.ParameterDataError.parametersWithinDifferentBank
        }
        
        // 檢驗陣列元素的位址是否依序。
        var examiningParameterDataList = self
        var reducedParameterData: ParameterData = examiningParameterDataList.removeFirst()
        for parameterData in examiningParameterDataList {
            guard reducedParameterData.address + reducedParameterData.length <= parameterData.address else {
                throw Array.ParameterDataError.parametersMisSequence
            }
            reducedParameterData = parameterData
        }
        
        let firstParameterData: ParameterData = self.first!
        let lastParameterData: ParameterData = self.last!
        return ParameterData(
            name: .INTEGRATED_MILEAGE_RECORD,
            partType: firstParameterData.partType,
            bank: firstParameterData.bank,
            address: firstParameterData.address,
            length: lastParameterData.address + lastParameterData.length - firstParameterData.address,
            type: firstParameterData.type
        )
    }
}
