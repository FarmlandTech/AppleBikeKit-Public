//
//  SystemTimeUpdateHelper.swift
//  
//
//  Created by Yves Tsai on 2023/5/29.
//

import Foundation
import Combine

/// 更新電控時間的處理物件。
final public class SystemTimeUpdateHelper {
    
    /// 更新電控時間，執行狀態的 Subject 。
    public private(set) lazy var stateSubject: CurrentValueSubject<Bool?, Never> = {
        .init(nil)
    }()
    
    /// 訂閱實例。
    private lazy var updatingSystemTimeStateSubscribe: AnyCancellable? = {
        nil
    }()
    
    /**
     建構子。
     */
    init() {
        self.updatingSystemTimeStateSubscribe = FarmLandBikeKit.sleipnir.updatingSystemTimeStatePublisher.sink(receiveValue: { state in
            self.stateSubject.send(state)
        })
    }
    
    /**
     解構子。
     */
    deinit {
        self.updatingSystemTimeStateSubscribe?.cancel()
    }
    
    /**
     開始執行任務。
     
     - Note: 會以遞迴的方式，不斷重新嘗試讀取參數，直到所有參數都完備才會停止。
     
     - Throws: 無法以名稱找到參數時，將會拋出 parameterDataNotFoundByName 錯誤。
     - Throws: 無法執行讀取參數命令時，將會拋出 readParameterFail 錯誤。
     */
    public func doTask() throws {
        try self.recurUpdateClock()
    }
    
    /**
     讀取參數的任務，具體執行內容。
     
     - Throws: 無法以名稱找到參數時，將會拋出 parameterDataNotFoundByName 錯誤。
     - Throws: 無法執行讀取參數命令時，將會拋出 readParameterFail 錯誤。
     */
    private func recurUpdateClock() throws {
        try FarmLandBikeKit.sleipnir.updateSystemTime()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.3) {
            guard let state: Bool = self.stateSubject.value, !state else { return }
            try? self.recurUpdateClock()
        }
    }
}
