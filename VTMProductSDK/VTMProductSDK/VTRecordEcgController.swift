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
    
    
    lazy var ecgWave: VTRecordEcgWave = {
        ecgWave = VTRecordEcgWave()
        ecgWave.layer.masksToBounds = true
        view.addSubview(ecgWave)
        ecgWave.mas_makeConstraints { (make) in
            if #available(iOS 11.0, *) {
                make?.top.equalTo()(view.mas_safeAreaLayoutGuideTop)
                make?.bottom.equalTo()(view.mas_safeAreaLayoutGuideBottom)
            } else {
                // Fallback on earlier versions
                make?.top.equalTo()(view)
                make?.bottom.equalTo()(view)
            }
            make?.left.equalTo()(view)
            make?.right.equalTo()(view)
        }
        return ecgWave
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        if ecgPoints != nil {
            ecgWave.startTime = removeLettersFromString(title!)
            ecgWave.sampleRate = 125
            ecgWave.ecgPoints = ecgPoints!
        }
        
    }
    
    
    func removeLettersFromString(_ str: String) -> String {
        let lettersSet = CharacterSet.letters
        let stringWithoutLetters = str.components(separatedBy: lettersSet).joined()
        return stringWithoutLetters
    }



}
