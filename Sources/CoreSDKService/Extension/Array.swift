//
//  File.swift
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
    public var mapBytes: Array<Int> {
        self.map({ UnsafeRawPointer($0).assumingMemoryBound(to: Int.self).pointee.littleEndian })
    }
}
