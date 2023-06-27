//
//  AssistPlanUpdateHelper.swift
//  
//
//  Created by Yves Tsai on 2023/6/15.
//

import Foundation
import Combine

import CoreSDKService

/// 助力等級的數據。
public struct AssistLevelRepository: Equatable {
    /// 第一段助力的最大值。
    public let LV1_MAX_AST_RATIO: Int
    /// 第一段助力的最小值。
    public let LV1_MIN_AST_RATIO: Int
    /// 第二段助力的最大值。
    public let LV2_MAX_AST_RATIO: Int
    /// 第二段助力的最小值。
    public let LV2_MIN_AST_RATIO: Int
    /// 第三段助力的最大值。
    public let LV3_MAX_AST_RATIO: Int
    /// 第三段助力的最小值。
    public let LV3_MIN_AST_RATIO: Int
    
    /// 實作 Equatable 協定，用以判斷兩個 AssistLevelRepository 的內容是否相同。
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.LV1_MAX_AST_RATIO == rhs.LV1_MAX_AST_RATIO &&
        lhs.LV1_MIN_AST_RATIO == rhs.LV1_MIN_AST_RATIO &&
        lhs.LV2_MAX_AST_RATIO == rhs.LV2_MAX_AST_RATIO &&
        lhs.LV2_MIN_AST_RATIO == rhs.LV2_MIN_AST_RATIO &&
        lhs.LV3_MAX_AST_RATIO == rhs.LV3_MAX_AST_RATIO &&
        lhs.LV3_MIN_AST_RATIO == rhs.LV3_MIN_AST_RATIO
    }
}

/// 存取助力等級的處理物件。
final public class AssistPlanUpdateHelper {
    
    public enum ReadingResult<T> {
        case prepared
        case `try`(Int)
        case done(T)
    }
    
    public enum WritingResult<T> {
        case prepared
        case `try`(Int, T)
        case done(T)
    }
    
    public enum Error: Swift.Error {
        case isReadRecursively
        case isWriteRecursively
    }
    
    private lazy var subscriptions: Set<AnyCancellable> = { .init() }()
    
    private let readingRecursivelyCountBoundary: Int = 3
    
    public private(set) lazy var readingSubject: CurrentValueSubject<AssistPlanUpdateHelper.ReadingResult<AssistLevelRepository?>, Never> = { .init(.done(nil)) }()
    
    private let writingRecursivelyCountBoundary: Int = 3
    
    public private(set) lazy var writingSubject: CurrentValueSubject<AssistPlanUpdateHelper.WritingResult<AssistLevelRepository?>, Never> = { .init(.done(nil)) }()
    
    private var subscribe: AnyCancellable?
    
    init() {
        //
        FarmLandBikeKit.sleipnir.parameterDataPubisher
            .sink(receiveCompletion: { _ in
                
            }, receiveValue: { [weak self] parameterData in
                guard let self: AssistPlanUpdateHelper else { return }
                guard parameterData.name == .INTEGRATED_ASSIST_LEVEL else { return }
                guard let parameters: [ParameterData] = parameterData.dividedParameters else { return }
                var LV1_MAX_AST_RATIO: Int?
                var LV1_MIN_AST_RATIO: Int?
                var LV2_MAX_AST_RATIO: Int?
                var LV2_MIN_AST_RATIO: Int?
                var LV3_MAX_AST_RATIO: Int?
                var LV3_MIN_AST_RATIO: Int?
                for parameter in parameters {
                    switch parameter.name {
                    case .LV1_MAX_AST_RATIO:
                        LV1_MAX_AST_RATIO = parameter.value as? Int
                    case .LV1_MIN_AST_RATIO:
                        LV1_MIN_AST_RATIO = parameter.value as? Int
                    case .LV2_MAX_AST_RATIO:
                        LV2_MAX_AST_RATIO = parameter.value as? Int
                    case .LV2_MIN_AST_RATIO:
                        LV2_MIN_AST_RATIO = parameter.value as? Int
                    case .LV3_MAX_AST_RATIO:
                        LV3_MAX_AST_RATIO = parameter.value as? Int
                    case .LV3_MIN_AST_RATIO:
                        LV3_MIN_AST_RATIO = parameter.value as? Int
                    default:
                        break
                    }
                }
                guard let LV1_MAX_AST_RATIO: Int else { return }
                guard let LV1_MIN_AST_RATIO: Int else { return }
                guard let LV2_MAX_AST_RATIO: Int else { return }
                guard let LV2_MIN_AST_RATIO: Int else { return }
                guard let LV3_MAX_AST_RATIO: Int else { return }
                guard let LV3_MIN_AST_RATIO: Int else { return }
                let repository: AssistLevelRepository = .init(
                    LV1_MAX_AST_RATIO: LV1_MAX_AST_RATIO,
                    LV1_MIN_AST_RATIO: LV1_MIN_AST_RATIO,
                    LV2_MAX_AST_RATIO: LV2_MAX_AST_RATIO,
                    LV2_MIN_AST_RATIO: LV2_MIN_AST_RATIO,
                    LV3_MAX_AST_RATIO: LV3_MAX_AST_RATIO,
                    LV3_MIN_AST_RATIO: LV3_MIN_AST_RATIO
                )
                if case .try(_) = self.readingSubject.value {
                    self.readingSubject.send(.done(repository))
                }
                if case .try(_, let target) = self.writingSubject.value, let target: AssistLevelRepository {
                    if target == repository {
                        self.writingSubject.send(.done(repository))
                    } else {
                        try? self.recurWriteValue(target)
                    }
                }
            })
            .store(in: &self.subscriptions)
        //
        FarmLandBikeKit.sleipnir.writingParameterStatePublisher
            .sink(receiveValue: { state in
                
            })
            .store(in: &self.subscriptions)
    }
    
    deinit {
        self.subscriptions.forEach({ $0.cancel() })
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
            try FarmLandBikeKit.sleipnir.readParameter(name: .INTEGRATED_ASSIST_LEVEL)
            DispatchQueue.global().asyncAfter(deadline: .now() + 1.9) { [weak self] in
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
        default:
            break
        }
    }
    
    public func write(
        LV1_MAX_AST_RATIO: Int,
        LV1_MIN_AST_RATIO: Int,
        LV2_MAX_AST_RATIO: Int,
        LV2_MIN_AST_RATIO: Int,
        LV3_MAX_AST_RATIO: Int,
        LV3_MIN_AST_RATIO: Int
    ) throws {
        guard case .done(_) = self.writingSubject.value else {
            throw Self.Error.isWriteRecursively
        }
        self.writingSubject.send(.prepared)
        try self.recurWriteValue(.init(
            LV1_MAX_AST_RATIO: LV1_MAX_AST_RATIO,
            LV1_MIN_AST_RATIO: LV1_MIN_AST_RATIO,
            LV2_MAX_AST_RATIO: LV2_MAX_AST_RATIO,
            LV2_MIN_AST_RATIO: LV2_MIN_AST_RATIO,
            LV3_MAX_AST_RATIO: LV3_MAX_AST_RATIO,
            LV3_MIN_AST_RATIO: LV3_MIN_AST_RATIO
        ))
    }
    
    private func recurWriteValue(_ repository: AssistLevelRepository) throws {
        
        func doTask() throws {
            let parameters: [(name: ParameterData.Name, value: Any)] = [
                (.LV1_MAX_AST_RATIO, repository.LV1_MAX_AST_RATIO),
                (.LV1_MIN_AST_RATIO, repository.LV1_MIN_AST_RATIO),
                (.LV2_MAX_AST_RATIO, repository.LV2_MAX_AST_RATIO),
                (.LV2_MIN_AST_RATIO, repository.LV2_MIN_AST_RATIO),
                (.LV3_MAX_AST_RATIO, repository.LV3_MAX_AST_RATIO),
                (.LV3_MIN_AST_RATIO, repository.LV3_MIN_AST_RATIO)
            ]
            for (index, parameter) in parameters.enumerated() {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.25 * Double(index)) {
                    try? FarmLandBikeKit.sleipnir.writeParameter(name: parameter.name, value: parameter.value)
                }
            }
            DispatchQueue.global().asyncAfter(deadline: .now() + 1.25 * Double(parameters.count)) { [weak self] in
                try? self?.read()
            }
        }
        
        switch self.writingSubject.value {
        case .prepared:
            self.writingSubject.send(.try(1, repository))
            try doTask()
        case .try(let count, _) where count < self.readingRecursivelyCountBoundary:
            self.writingSubject.send(.try(count + 1, repository))
            try doTask()
        default:
            break
        }
    }
}

