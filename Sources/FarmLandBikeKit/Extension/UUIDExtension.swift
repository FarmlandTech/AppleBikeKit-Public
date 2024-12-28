//
//  UUIDExtension.swift
//  FarmLandBikeKit
//
//  Created by Yves Tsai on 2024/12/26.
//

import Foundation

extension UUID {
    var toToken: String {
        self.uuidString.replacingOccurrences(of: "-", with: "")
    }
}
