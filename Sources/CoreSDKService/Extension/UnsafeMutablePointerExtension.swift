//
//  UnsafeMutablePointerExtension.swift
//  
//
//  Created by Yves Tsai on 2023/4/21.
//

import Foundation

extension UnsafeMutablePointer where Pointee == UInt8 {
    
    public func convert2Bytes(length: Int) -> Array<UInt8> {
        var bytes: [UInt8] = .init()
        for index in 0..<length {
            bytes.append(self[index])
        }
        return bytes
    }
}
