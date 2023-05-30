//
//  SystemTimeUpdateHelper.swift
//  
//
//  Created by Yves Tsai on 2023/5/29.
//

import Foundation
import Combine

final public class SystemTimeUpdateHelper {
    
    public private(set) lazy var stateSubject: CurrentValueSubject<Bool?, Never> = {
        .init(nil)
    }()
    
    private lazy var updatingSystemTimeStateSubscribe: AnyCancellable? = {
        nil
    }()
    
    init() {
        self.updatingSystemTimeStateSubscribe = FarmLandBikeKit.sleipnir.updatingSystemTimeStatePublisher.sink(receiveValue: { state in
            self.stateSubject.send(state)
        })
    }
    
    deinit {
        self.updatingSystemTimeStateSubscribe?.cancel()
    }
    
    func doTask() throws {
        try self.recurUpdateClock()
    }
    
    private func recurUpdateClock() throws {
        try FarmLandBikeKit.sleipnir.updateSystemTime()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.3) {
            guard let state: Bool = self.stateSubject.value, !state else { return }
            try? self.recurUpdateClock()
        }
    }
}
