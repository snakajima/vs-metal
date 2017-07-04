//
//  VSRuntime.swift
//  vs-metal
//
//  Created by SATOSHI NAKAJIMA on 6/27/17.
//  Copyright © 2017 SATOSHI NAKAJIMA. All rights reserved.
//

import Foundation
import Metal

/// A runtime object generated from a VSScript object (by calling its compile() method).
/// It contains an array of VSNode objects, and an array of objects that conform to VSDynamicVariable protocol
struct VSRuntime {
    /// an array of VSNode objects
    private let nodes:[VSNode]
    /// an array of objects that conform to VSDynamicVariable protocol
    private let dynamicVariables:[VSDynamicVariable]
    
    init(nodes:[VSNode], dynamicVariables:[VSDynamicVariable]) {
        self.nodes = nodes
        self.dynamicVariables = dynamicVariables
    }

    func encode(commandBuffer:MTLCommandBuffer, context:VSContext) throws -> MTLCommandBuffer {
        assert(Thread.current == Thread.main)
        
        var dictionary = [String:[Float]]()
        for dynamicVariable in dynamicVariables {
            dynamicVariable.apply(callback: { (key, values) in
                dictionary[key] = values
            })
        }
        context.updateNamedBuffers(with: dictionary)
 
        for node in nodes {
            try node.encode(commandBuffer:commandBuffer, destination:context.getDestination(), context:context)
        }
        
        return commandBuffer
    }
}
