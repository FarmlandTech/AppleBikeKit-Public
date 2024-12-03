//
//  UpgradingRawData.swift
//  
//
//  Created by Yves Tsai on 2023/9/8.
//

import Foundation

import CoreSDKSourceCode

public struct UpgradingRawData: CustomStringConvertible {
    
    private let pointer: UnsafePointer<CChar>?
    public let progress: Int32
    
    public var message: String? {
        guard let pointer: UnsafePointer<CChar> else {
            return nil
        }
        guard let result: String = .init(validatingUTF8: pointer) else {
            return nil
        }
        return result
    }
    
    public var description: String {
        return "progress: ❄️\(progress)❄️; message: \(String(describing: self.message))"
    }
    
    init(pointer: UnsafePointer<CChar>?, progress: Int32) {
        self.pointer = pointer
        self.progress = progress
    }
}
