//
//  VSRuntime.swift
//  vs-metal
//
//  Created by SATOSHI NAKAJIMA on 6/27/17.
//  Copyright © 2017 SATOSHI NAKAJIMA. All rights reserved.
//

import Foundation

/// A runtime object generated from a VSScript object (by calling its compile() method).
/// It contains an array of VSNode objects, and an array of objects that conform to VSDynamicVariable protocol
struct VSRuntime {
    /// an array of VSNode objects
    let nodes:[VSNode]
    /// an array of objects that conform to VSDynamicVariable protocol
    let dynamicVariables:[VSDynamicVariable]
}
