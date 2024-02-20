//
//  DisguiseBatteryHelper.swift
//  
//
//  Created by Yves Tsai on 2023/7/6.
//

import Foundation
import Combine

/// 判斷 BMS 是否具有通訊功能的處理物件。
final public class DisguiseBatteryHelper {
    
    public enum ReadingResult<T> {
        case prepared
        case `try`(Int)
        case done(T)
    }
    
    public enum Error: Swift.Error {
        case parameterNotFound
        case isReadRecursively
    }
    
    private lazy var subscribe: AnyCancellable? = { nil }()
    
    private let readingRecursivelyCountBoundary: Int = 3
    
    public private(set) lazy var readingSubject: CurrentValueSubject<DisguiseBatteryHelper.ReadingResult<Bool?>, Never> = { .init(.done(nil)) }()
    
    init() throws {
        guard let index: Int = FarmLandBikeKit.sleipnir.parameterDataRepository.parameters.firstIndex(where: { $0.name == .DISGUISE_BATT }) else {
            throw Self.Error.parameterNotFound
        }
        self.subscribe = FarmLandBikeKit.sleipnir.parameterDataRepository.parameters[index].subject
            .compactMap({ $0 as? Int })
            .map({
                switch $0 {
                case 0:
                    return true
                case 1:
                    return false
                default:
                    return nil
                }
            })
            .compactMap({ $0 })
            .sink(receiveValue: { [weak self] in
                self?.readingSubject.send(.done($0))
            })
    }
    
    public func read() throws {
        guard case .done(_) = self.readingSubject.value else {
            throw Self.Error.isReadRecursively
        }
        self.readingSubject.send(.prepared)
        try self.recurReadValue()
    }
    
    private func recurReadValue() throws {
        
        func doTask() throws {
            try FarmLandBikeKit.sleipnir.readParameter(name: .DISGUISE_BATT)
            DispatchQueue.global().asyncAfter(deadline: .now() + 1.3) { [weak self] in
                try? self?.recurReadValue()
            }
        }
        
        switch self.readingSubject.value {
        case .prepared:
            self.readingSubject.send(.try(1))
            try doTask()
        case .try(let count) where count < self.readingRecursivelyCountBoundary:
            self.readingSubject.send(.try(count + 1))
            try doTask()
        case .try(let count) where count >= self.readingRecursivelyCountBoundary:
            self.readingSubject.send(.done(nil))
        default:
            break
        }
    }
}
