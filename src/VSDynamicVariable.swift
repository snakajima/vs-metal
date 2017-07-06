//
//  VSDynamicVariable.swift
//  vs-metal
//
//  Created by satoshi on 6/27/17.
//  Copyright © 2017 SATOSHI NAKAJIMA. All rights reserved.
//

import Foundation

/// VSDynamicVariable is a protocol for "dynamic variable" objects must conform to.
/// "Dynamic variable" objects can change the value of named variables
protocol VSDynamicVariable {
    /// For each frame, the VSRuntime object calls this method of all dynamic variable objects
    /// attached to the video pipeline.
    ///
    /// - Parameter callback: it calls back this function to modify variables
    func apply(callback:(String, [Float])->())
}

/// VSTimer is a concrete implementation of VSDynamicVariable, which modifies a named variable
/// in a specified interval.
struct VSTimer:VSDynamicVariable {
    private let key:String
    private let interval:Double
    private let range:[Float]
    
    /// Initializer
    ///
    /// - Parameters:
    ///   - key: the name of variable (to modify for each frame)
    ///   - params: a dictionary of parameters ("interval" and "range")
    init(key:String, params:[String:Any]) {
        self.key = key
        if let interval = VSScript.floatValues(params: params, key: "interval"), interval.count == 1 {
            self.interval = Double(interval[0])
        } else {
            self.interval = 1.0
        }
        if let range = VSScript.floatValues(params: params, key: "range"), range.count == 2 {
            self.range = range
        } else {
            self.range = [0.0, 1.0]
        }
    }
    
    func apply(callback:(String, [Float])->()) {
        let date = NSDate().timeIntervalSince1970
        let value = range[0] + (range[1]-range[0]) * (Float(sin(date * .pi * 2.0 / self.interval) + 1.0) / 2.0)
        callback(key, [value])
    }
}



