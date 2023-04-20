//
//  RawData.swift
//  
//
//  Created by Yves Tsai on 2023/4/18.
//

import Foundation

import CoreSDK

struct RawData {
    var returnState: Int32
    var targetDevice: DeviceType_enum
    var readBuff: [UInt8]
    var addrs: UInt16
    var leng: UInt16
    var bank: UInt8
    
    init(returnState: Int32, targetDevice: DeviceType_enum, readBuff: [UInt8], addrs: UInt16, leng: UInt16, bank: UInt8) {
        self.returnState = returnState
        self.targetDevice = targetDevice
        self.readBuff = readBuff
        self.addrs = addrs
        self.leng = leng
        self.bank = bank
    }
}
