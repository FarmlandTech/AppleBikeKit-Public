//
//  MainViewModel.swift
//  DST
//
//  Created by abe chen on 2022/10/12.
//

import Foundation

enum PartType {
    case Hmi
    case Controlelr
    case Motor
    case Battery
    case Torque
    case Throttle
    case Elock
    case Lights
}

struct Part: Identifiable {
    let id: UUID = UUID()
    let mid: String?
    let sn: String?
    let name: String
    let fwVersion: String?
    let manufactureDate: String?
    let bgIcon: String?
    let partIcon: String?
}

class MainViewModel: ObservableObject {
    @Published var fakePartList: [Part] = [
        Part(mid: "FBC22220110987", sn: "FLBCO01220601", name: "Controller", fwVersion: "A03", manufactureDate: "20220615", bgIcon: "controller_bg_icon", partIcon: "controller_icon"),
        Part(mid: "FBC22220110987", sn: "FLBCO01220601", name: "Battery", fwVersion: "A03", manufactureDate: "20220615", bgIcon: "battery_bg_icon", partIcon: "battery_icon"),
        Part(mid: "FBC22220110987", sn: "FLBCO01220601", name: "Motor", fwVersion: "A03", manufactureDate: "20220615", bgIcon: "motor_bg_icon", partIcon: "motor_icon"),
        Part(mid: "FBC22220110987", sn: "FLBCO01220601", name: "Torque", fwVersion: "A03", manufactureDate: "20220615", bgIcon: "torque_bg_icon", partIcon: "torque_icon"),
        Part(mid: "FBC22220110987", sn: "FLBCO01220601", name: "HMI", fwVersion: "A03", manufactureDate: "20220615", bgIcon: "hmi_bg_icon", partIcon: "hmi_icon"),
        Part(mid: "FBC22220110987", sn: "FLBCO01220601", name: "E-Lock", fwVersion: "A03", manufactureDate: "20220615", bgIcon: "e-lock_bg_icon", partIcon: "e-lock_icon"),
        Part(mid: "FBC22220110987", sn: "FLBCO01220601", name: "Lights",  fwVersion: "A03", manufactureDate: "20220615", bgIcon: "lights_bg_icon", partIcon: "lights_icon"),
        Part(mid: "FBC22220110987", sn: "FLBCO01220601", name: "Throttle",  fwVersion: "A03", manufactureDate: "20220615", bgIcon: "throttle_bg_icon", partIcon: "throttle_icon")
    ]
}
