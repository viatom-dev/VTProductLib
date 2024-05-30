//
//  VTRecordEcgWave.swift
//  VTMProductSDK
//
//  Created by yangweichao on 2024/1/9.
//  Copyright © 2024 viatom. All rights reserved.
//

import UIKit

class VTRecordEcgWave: UIView {
    public var ecgPoints: [Double]! {
        didSet {
            if bounds.height == 0 {
                return
            }
            refresh()
        }
    }
    public var sampleRate: Int!{
        didSet {
            mmPerVal = Double(rate) / Double(sampleRate)
            ptPerVal = ptPerMm * mmPerVal
        }
    }
    
    // MARK: start measure time.  yyyyMMddHHmmss
    public var startTime: String! {
        didSet {
            print("startTime" + startTime)
        }
    }
    
    public var mmPerMV = 10.0  // 1mV <--> 10mm
    public var rate = 25.0  // 25mm <--> 1s
    
    
    let gridPerThick = 5    // the number of small grids in each large grid.
    let gridPerRow = 5 * 5  // the number of small grids in each row.
    let gridUpper = 5 * 3   // the number of small grids above baseline.
    let gridLower = 5 * 2   // the number of small grids below baseline.
    let ptPerMm: Double = 6.4 // pts per millimeter.
    
    var mmPerVal: Double!
    var ptPerVal: Double!
    var offset: Double! = 0.0
    
    lazy var waveLayer: CAShapeLayer = {
        waveLayer = CAShapeLayer.init()
        waveLayer.strokeColor = UIColor(red: 0.32, green: 0.83, blue: 0.42, alpha: 1.0).cgColor
        waveLayer.fillColor = UIColor.clear.cgColor
        waveLayer.lineWidth = 1.0
        layer.addSublayer(waveLayer)
        return waveLayer
    }()
    
    lazy var thickLayer: CAShapeLayer = {
        thickLayer = CAShapeLayer.init()
        thickLayer.strokeColor = UIColor.gray.cgColor
        thickLayer.fillColor = UIColor.clear.cgColor
        thickLayer.lineWidth = 0.5
        layer.addSublayer(thickLayer)
        return thickLayer
    }()
    
    lazy var thinLineLayer: CAShapeLayer = {
        
        thinLineLayer = CAShapeLayer.init()
        thinLineLayer.strokeColor = UIColor.gray.cgColor
        thinLineLayer.fillColor = UIColor.clear.cgColor
        thinLineLayer.lineWidth = 0.1
        layer.addSublayer(thinLineLayer)
        return thinLineLayer

    }()
    
    // MARK: func button, adjust speed or gain. completion by setting the property rate or setting the property mmPerMV
    lazy var rateButton: UIButton = {
        rateButton = UIButton(frame: CGRect(x: 10, y: 10, width: 120, height: 30))
        rateButton.backgroundColor = UIColor.blue
        rateButton.setTitleColor(UIColor.white, for: .normal);
        rateButton.addTarget(self, action: #selector(self.rateDidChange(sender:)), for: .touchUpInside)
        self.addSubview(rateButton)
        return rateButton
    }()
    
    lazy var gainButton: UIButton = {
        gainButton = UIButton(frame: CGRect(x: 160, y: 10, width: 120, height: 30))
        gainButton.backgroundColor = UIColor.blue
        gainButton.setTitleColor(UIColor.white, for: .normal)
        gainButton.addTarget(self, action: #selector(self.gainDidChange(sender:)), for: .touchUpInside)
        self.addSubview(gainButton)
        return gainButton
    }()
    // ---------------------------------------
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.white
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(self.panGesture(recognizer:)))
        self.addGestureRecognizer(gesture)
        sampleRate = 125
        rateButton.setTitle("25 mm/s", for: .normal)
        gainButton.setTitle("10 mm/mV", for: .normal)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if ecgPoints.count > 0 {
            refresh()
        }
    }
    
    @objc func panGesture(recognizer: UIPanGestureRecognizer) {
        
        if recognizer.state == .changed {
            let point = recognizer.translation(in: self)
            offset -= point.y
            print("偏移量1：",point.y)
            if offset < 0 {
                offset = 0
            }
            
            let valPerRow = floor(bounds.width / ptPerVal)
            let offsetLimitRow = ceil(Double(ecgPoints.count) / valPerRow)
            let offsetLimitPt = offsetLimitRow * Double(gridPerRow) * ptPerMm
            
            if offset > offsetLimitPt - bounds.height {
                offset = offsetLimitPt - bounds.height
            }
            if offset < 0 {
                offset = 0
            }
            print("偏移量2：", offset)
            recognizer.setTranslation(CGPointZero, in: self)
            refresh()
        }
    }
    
    @objc func rateDidChange(sender: UIButton) {
        if sender.titleLabel?.text == "25 mm/s" {
            sender.setTitle("6.25 mm/s", for: .normal)
            rate = 6.25
        } else if sender.titleLabel?.text == "12.5 mm/s" {
            sender.setTitle("25 mm/s", for: .normal)
            rate = 25.0
        } else {
            sender.setTitle("12.5 mm/s", for: .normal)
            rate = 12.5
        }
        mmPerVal = Double(rate) / Double(sampleRate)
        ptPerVal = ptPerMm * mmPerVal
        offset = 0
        refresh()
    }
    
    @objc func gainDidChange(sender: UIButton) {
        if sender.titleLabel?.text == "10 mm/mV" {
            sender.setTitle("20 mm/mV", for: .normal)
            mmPerMV = 20.0
        } else if sender.titleLabel?.text == "20 mm/mV" {
            sender.setTitle("5 mm/mV", for: .normal)
            mmPerMV = 5.0
        } else {
            sender.setTitle("10 mm/mV", for: .normal)
            mmPerMV = 10.0
        }
        refresh()
    }
    
    func refresh() {
        drawGrid()
        drawEcgWave()
    }
    
    
    func drawGrid() {
        
        // 确定第一条数据基线
        let offsetMM = fmod(offset,  ptPerMm * Double(gridPerRow))
        let firstBaseLineY = Double(gridUpper) * ptPerMm  - offsetMM
        
        var lineY = firstBaseLineY
        var count = 0
        let thinPath = CGMutablePath()
        let thickPath = CGMutablePath()
        while lineY <= bounds.height {
            let startPoint = CGPoint(x: 0.0, y: lineY)
            let endPoint = CGPoint(x: bounds.width, y: lineY)
            thinPath.move(to: startPoint)
            thinPath.addLine(to: endPoint)
            if count % gridPerThick == 0 {
                thickPath.move(to: startPoint)
                thickPath.addLine(to: endPoint)
            }
            lineY += ptPerMm
            count += 1
        }
        lineY = firstBaseLineY
        count = 0
        while lineY >= 0 {
            let startPoint = CGPoint(x: 0.0, y: lineY)
            let endPoint = CGPoint(x: bounds.width, y: lineY)
            thinPath.move(to: startPoint)
            thinPath.addLine(to: endPoint)
            if count % gridPerThick == 0 {
                thickPath.move(to: startPoint)
                thickPath.addLine(to: endPoint)
            }
            lineY -= ptPerMm
            count += 1
        }
        
        var lineX: Double = 0.0
        count = 0
        while lineX <= bounds.width {
            let startPoint = CGPoint(x: lineX, y: 0)
            let endPoint = CGPoint(x: lineX, y: bounds.height)
            thinPath.move(to: startPoint)
            thinPath.addLine(to: endPoint)
            if count % gridPerThick == 0 {
                thickPath.move(to: startPoint)
                thickPath.addLine(to: endPoint)
            }
            lineX += ptPerMm
            count += 1
        }
        thinLineLayer.path = thinPath
        thickLayer.path = thickPath
    }
    
    func drawEcgWave() {
        
        for sublayer in layer.sublayers! {
            if sublayer.isMember(of: CATextLayer.self) {
                sublayer.removeFromSuperlayer()
            }
        }
        
        let valPerRow = floor(bounds.width / ptPerVal)
        let offsetRow = floor(offset / (ptPerMm * Double(gridPerRow)))
        let mmFirstRow = fmod(offset,  ptPerMm * Double(gridPerRow))
        let firstIdx = Int(valPerRow * offsetRow)
        var i = firstIdx
        print(firstIdx, offset)
        var canBreak = false
        let wavePath = CGMutablePath()
        let startStamp = VTDateUtil.timestampWith(dateStr: startTime)
        while i < ecgPoints.count  {
            let val = ecgPoints[i]
            let mod = (i - firstIdx) % Int(valPerRow)
            let row = (i - firstIdx) / Int(valPerRow)
            let x = Double(mod) * ptPerVal
            let y0 = Double(row) * Double(gridPerRow)  + Double(gridUpper)
            let y = y0 * ptPerMm - val * mmPerMV * ptPerMm  - mmFirstRow
            if mod != 0 {
                if y <= bounds.height {
                    canBreak = false
                }
                wavePath.addLine(to: CGPointMake(x, y))
            } else {
                if canBreak == true {
                    break
                }
                if y > bounds.height {
                    canBreak = true
                }
                wavePath.move(to: CGPointMake(x, y))
                
                let currentStamp = startStamp + Double(i) / Double(sampleRate)
                let textLayer = CATextLayer()
                textLayer.frame = CGRect(x: 10, y: y0 * ptPerMm + Double(gridLower)*ptPerMm - 20 - mmFirstRow, width: 200, height: 20)
                textLayer.contentsScale = UIScreen.main.scale
                let font = UIFont.systemFont(ofSize: 12)
                let strRef = CGFont.init(font.fontName as CFString)
                textLayer.font = strRef
                textLayer.fontSize = UIFont.systemFont(ofSize: 12).pointSize
                textLayer.foregroundColor = UIColor.black.cgColor
                textLayer.string = VTDateUtil.showDateStrWith(timestamp: currentStamp)
                layer.addSublayer(textLayer)
                
            }
            i += 1
        }
        waveLayer.path = wavePath
    }
    
}

class VTDateUtil: NSObject {
    class func showDateStrWith(dateStr: String) -> String {
//        let dateFormater = DateFormatter()
//        dateFormater.locale = NSLocale.current
//        dateFormater.dateFormat = "yyyyMMddHHmmss"
//        let date = dateFormater.date(from: dateStr) ?? nil
//        guard let date = date else { return "" }
//        dateFormater.dateFormat = "yyyy/MM/dd HH:mm:ss"
//        let str = dateFormater.string(from: date)
//        return str
        let year = dateStr.prefix(4)
        let month = dateStr.dropFirst(4).dropLast(8)
        let day = dateStr.dropFirst(6).dropLast(6)
        let hour = dateStr.dropFirst(8).dropLast(4)
        let minute = dateStr.dropFirst(10).dropLast(2)
        let sec = dateStr.suffix(2)
        return year + "/" + month + "/" + day + " " + hour + ":" + minute + ":" + sec
    }
    
    class func timestampWith(dateStr: String) -> TimeInterval {
        let dateFormater = DateFormatter()
        dateFormater.locale = NSLocale.current
        dateFormater.dateFormat = "yyyyMMddHHmmss"
        let date = dateFormater.date(from: dateStr) ?? nil
        guard let date = date else { return 0 }
        return date.timeIntervalSince1970
    }
    
    class func showDateStrWith(timestamp: TimeInterval) -> String {
        let date = Date.init(timeIntervalSince1970: timestamp)
        let dateFormater = DateFormatter()
        dateFormater.locale = NSLocale.current
        dateFormater.dateFormat = "yyyy/MM/dd HH:mm:ss"
        let str = dateFormater.string(from: date)
        return str
    }
    
}
