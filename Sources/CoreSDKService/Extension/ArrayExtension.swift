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
