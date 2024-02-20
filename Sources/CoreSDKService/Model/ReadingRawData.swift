//
//  RawData.swift
//  
//
//  Created by Yves Tsai on 2023/4/18.
//

import Foundation

import CoreSDKSourceCode

public struct ReadingRawData {
    
    public let device: DeviceType_enum
    public let bank: UInt8
    public let address: UInt16
    public let length: UInt16
    public let state: Bool
    private let pointer: UnsafeMutablePointer<UInt8>
    
    public var bytes: [UInt8] {
        let length: Int = .init(self.length)
        return self.pointer.convert2Bytes(length: length)
    }
    
    init(device: DeviceType_enum, bank: UInt8, address: UInt16, length: UInt16, state: Bool, pointer: UnsafeMutablePointer<UInt8>) {
        self.device = device
        self.bank = bank
        self.address = address
        self.length = length
        self.state = state
        self.pointer = pointer
    }
}
