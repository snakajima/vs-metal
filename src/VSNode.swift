//
//  VSNode.swift
//  vs-metal
//
//  Created by SATOSHI NAKAJIMA on 6/22/17.
//  Copyright © 2017 SATOSHI NAKAJIMA. All rights reserved.
//

import Foundation
import MetalPerformanceShaders

/// VSNode is a protocol for nodes in the video pipeline must conform to.
protocol VSNode {
    /// Either encode appropriate GPU instructions into the command buffer (VSFilter and VSMPSFilter)
    /// or manipulate texture stack (VSController).
    ///
    /// - Parameters:
    ///   - commandBuffer: The command buffer to encode to
    ///   - context: the video pipeline context
    /// - Throws: VSContextError.underUnderflow if pop() was called when the stack is empty
    func encode(commandBuffer:MTLCommandBuffer, context:VSContext) throws
}


