//
//  VSVariable.swift
//  vs-metal
//
//  Created by satoshi on 6/27/17.
//  Copyright © 2017 SATOSHI NAKAJIMA. All rights reserved.
//

import UIKit

protocol VSVariable {
    func apply(callback:(String, [Float])->())
}

class VSTimer:VSVariable {
    let key:String
    let ratio = 5.0
    init(key:String, params:[String:Any]) {
        self.key = key
    }
    
    func apply(callback:(String, [Float])->()) {
        let date = NSDate().timeIntervalSince1970
        let value = (Float(sin(date * .pi * self.ratio)) + 1.0) / 2.0
        callback(key, [value])
    }
}



