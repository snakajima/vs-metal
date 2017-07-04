//
//  VSNode.swift
//  vs-metal
//
//  Created by SATOSHI NAKAJIMA on 6/22/17.
//  Copyright © 2017 SATOSHI NAKAJIMA. All rights reserved.
//

import Foundation
import MetalPerformanceShaders

/// VSNode is a protocol for objects in the video pipeline must conform to.
protocol VSNode {
    /// Either encode appropriate GPU instructions into the command buffer (VSFilter and VSMPSFilter)
    /// or manipulate texture stack (VSFork, VSSwap, VSDiscard, VSShift and VSPrevious).
    ///
    /// - Parameters:
    ///   - commandBuffer: The command buffer to encode to
    ///   - destination: the target texture to render to
    ///   - context: the video pipeline context
    /// - Throws: VSContextError.underUnderflow if pop() was called when the stack is empty
    func encode(commandBuffer:MTLCommandBuffer, destination:VSTexture, context:VSContext) throws
}


