//
//  RawData.swift
//  
//
//  Created by Yves Tsai on 2023/4/18.
//

import Foundation

import CoreSDK

public struct RawData {
    
    public private(set) var targetDevice: DeviceType_enum
    public private(set) var bank: UInt8
    public private(set) var address: UInt16
    public private(set) var length: UInt16
    var returnState: Int32
    let pointer: UnsafeMutablePointer<UInt8>
    
    public var bytes: [UInt8] {
        let length: Int = .init(self.length)
        return self.pointer.convert2Bytes(length: length)
    }
    
    init(targetDevice: DeviceType_enum, bank: UInt8, address: UInt16, length: UInt16, returnState: Int32, pointer: UnsafeMutablePointer<UInt8>) {
        self.targetDevice = targetDevice
        self.bank = bank
        self.address = address
        self.length = length
        self.returnState = returnState
        self.pointer = pointer
    }
}
