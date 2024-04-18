//
//  VTSwiftParser.swift
//  VTMProductSDK
//
//  Created by yangweichao on 2024/1/16.
//  Copyright © 2024 viatom. All rights reserved.
//

import UIKit

@objcMembers class VTSwiftParser: NSObject {

    // MARK: BP2 Series
    static func swift_parseBPEndMeasureData(response: Data) {
        let bpEndMeasureData: VTMBPEndMeasureData = VTMBLEParser.parseBPEndMeasure(response)
        let dia = bpEndMeasureData.diastolic_pressure
        let sys = bpEndMeasureData.systolic_pressure
        print("DIA:" + String(dia))
        print("SYS:" + String(sys))
    }
    
    
    
}
