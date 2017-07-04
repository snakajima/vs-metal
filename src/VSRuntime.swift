//
//  VSRuntime.swift
//  vs-metal
//
//  Created by SATOSHI NAKAJIMA on 6/27/17.
//  Copyright © 2017 SATOSHI NAKAJIMA. All rights reserved.
//

import Foundation
import Metal

/// A runtime object which represents a video pipeline. 
/// It contains an array of VSNode objects, and an array of objects that conform to VSDynamicVariable protocol.
/// It is generated from a VSScript object by calling its compile() method.
struct VSRuntime {
    private let nodes:[VSNode]
    private let dynamicVariables:[VSDynamicVariable]
    
    /// Initializer
    ///
    /// - Parameters:
    ///   - nodes: an array of VSNode objects to be processed in the video pipeline
    ///   - dynamicVariables: an array of objects that alters dynamic variables
    init(nodes:[VSNode], dynamicVariables:[VSDynamicVariable]) {
        self.nodes = nodes
        self.dynamicVariables = dynamicVariables
    }

    /// Encode the video pipeline instructions into the specified command buffer
    ///
    /// - Parameters:
    ///   - commandBuffer: the command buffer to encode to
    ///   - context: the pipeline context
    /// - Returns: the specified command buffer
    /// - Throws: VSContextError.underUnderflow if pop() was called when the stack is empty
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
            try node.encode(commandBuffer:commandBuffer, context:context)
        }
        
        return commandBuffer
    }
}
