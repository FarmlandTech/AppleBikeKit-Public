//
//  AssistSettingModel.swift
//  AppleBikeKit
//
//  Created by Yves Tsai on 2025/2/26.
//

import CoreSDKServiceSourceCode

public struct AssistSettingModel {
    public let lv1: AssistSettingModel.LevelSettingModel?
    public let lv2: AssistSettingModel.LevelSettingModel?
    public let lv3: AssistSettingModel.LevelSettingModel?
    public let lv4: AssistSettingModel.LevelSettingModel?
    public let lv5: AssistSettingModel.LevelSettingModel?
    
    init(parameterDataList: [ParameterData]) {
        self.lv1 = .init(
            ratio: parameterDataList.first(where: { $0.name == ParameterData.Apple.Name.Controller_P_LV1_MAX_AST_RATIO.rawValue }),
            maxSpeed: parameterDataList.first(where: { $0.name == ParameterData.Apple.Name.Controller_P_LV1_AST_RATIO_END_SPD.rawValue })
        )
        self.lv2 = .init(
            ratio: parameterDataList.first(where: { $0.name == ParameterData.Apple.Name.Controller_P_LV2_MAX_AST_RATIO.rawValue }),
            maxSpeed: parameterDataList.first(where: { $0.name == ParameterData.Apple.Name.Controller_P_LV2_AST_RATIO_END_SPD.rawValue })
        )
        self.lv3 = .init(
            ratio: parameterDataList.first(where: { $0.name == ParameterData.Apple.Name.Controller_P_LV3_MAX_AST_RATIO.rawValue }),
            maxSpeed: parameterDataList.first(where: { $0.name == ParameterData.Apple.Name.Controller_P_LV3_AST_RATIO_END_SPD.rawValue })
        )
        self.lv4 = .init(
            ratio: parameterDataList.first(where: { $0.name == ParameterData.Apple.Name.Controller_P_LV4_MAX_AST_RATIO.rawValue }),
            maxSpeed: parameterDataList.first(where: { $0.name == ParameterData.Apple.Name.Controller_P_LV4_AST_RATIO_END_SPD.rawValue })
        )
        self.lv5 = .init(
            ratio: parameterDataList.first(where: { $0.name == ParameterData.Apple.Name.Controller_P_LV5_MAX_AST_RATIO.rawValue }),
            maxSpeed: parameterDataList.first(where: { $0.name == ParameterData.Apple.Name.Controller_P_LV5_AST_RATIO_END_SPD.rawValue })
        )
    }
    
    public init(lv1: AssistSettingModel.LevelSettingModel? = nil, lv2: AssistSettingModel.LevelSettingModel? = nil, lv3: AssistSettingModel.LevelSettingModel? = nil, lv4: AssistSettingModel.LevelSettingModel? = nil, lv5: AssistSettingModel.LevelSettingModel? = nil) {
        self.lv1 = lv1
        self.lv2 = lv2
        self.lv3 = lv3
        self.lv4 = lv4
        self.lv5 = lv5
    }
}

extension AssistSettingModel {
    public struct LevelSettingModel {
        /// 助力比。(單位：%)
        public let ratio: Double?
        /// 最大速度。(單位：km)
        public let maxSpeed: Double?
        
        var ratioRawValue: Int? {
            if let rawValue: Double = self.ratio.map({ $0 * 360 / 100 }) {
                return .init(rawValue)
            } else {
                return nil
            }
        }
        
        var maxSpeedRawValue: Int? {
            if let rawValue: Double = self.maxSpeed.map({ $0 * 10 }) {
                return .init(rawValue)
            } else {
                return nil
            }
        }
        
        init(ratio: ParameterData?, maxSpeed: ParameterData?) {
            self.ratio = (ratio?.value as? Int)
                .map({ Double($0) })
                .map({ $0 * 100 / 360 })
            self.maxSpeed = (maxSpeed?.value as? Int)
                .map({ Double($0) })
                .map({ $0 / 10 })
        }
        
        public init(ratio: Double?, maxSpeed: Double?) {
            self.ratio = ratio
            self.maxSpeed = maxSpeed
        }
    }
}
