//
//  VTRecordEcgController.swift
//  VTMProductSDK
//
//  Created by yangweichao on 2024/1/10.
//  Copyright © 2024 viatom. All rights reserved.
//

import UIKit

@objcMembers class VTRecordEcgController: UIViewController {
    
    public var ecgPoints: [Double]?
    public var sampleRate: Int = 125
    
    
    lazy var ecgWave: VTRecordEcgWave = {
        ecgWave = VTRecordEcgWave(frame: self.view.bounds)
        view.addSubview(ecgWave)
        return ecgWave
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if ecgPoints != nil {
            ecgWave.sampleRate = sampleRate
            ecgWave.ecgPoints = ecgPoints!
        }
        
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
