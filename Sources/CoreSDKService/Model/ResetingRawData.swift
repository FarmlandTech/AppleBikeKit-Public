//
//  ResetingRawData.swift
//  
//
//  Created by Yves Tsai on 2023/6/27.
//

import Foundation

import CoreSDKSourceCode

public struct ResetingRawData {
    
    public let device: DeviceType_enum
    public let bank: UInt8
    public let state: Bool
    
    init(device: DeviceType_enum, bank: UInt8, state: Bool) {
        self.device = device
        self.bank = bank
        self.state = state
    }
}
