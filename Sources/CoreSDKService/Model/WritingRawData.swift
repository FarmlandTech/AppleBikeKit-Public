//
//  WritingRawData.swift
//  
//
//  Created by Yves Tsai on 2023/6/27.
//

import Foundation

import CoreSDKSourceCode

public struct WritingRawData {
    
    public let device: DeviceType_enum
    public let bank: UInt8
    public let address: UInt16
    public let length: UInt16
    public let state: Bool
    
    init(device: DeviceType_enum, bank: UInt8, address: UInt16, length: UInt16, state: Bool) {
        self.device = device
        self.bank = bank
        self.address = address
        self.length = length
        self.state = state
    }
}
