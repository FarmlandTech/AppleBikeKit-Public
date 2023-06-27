//
//  IntExtension.swift
//  
//
//  Created by Yves Tsai on 2023/6/26.
//

import Foundation

extension Int {
    /// 公里轉英里。
    var toMile: Int {
        Int(Double(self).toMile)
    }
}
