//
//  BaseResponse.swift
//  DST
//
//  Created by abe chen on 2022/10/27.
//

import Foundation

struct BaseResponse<T : Codable>: Codable {
    let message: String
    let data: T?
    let token: String?
}

struct EmptyData: Codable {
    let null: String?
}
