//
//  VSFilter.swift
//  vs-metal
//
//  Created by SATOSHI NAKAJIMA on 6/22/17.
//  Copyright © 2017 SATOSHI NAKAJIMA. All rights reserved.
//

import Foundation
import MetalKit

class VSFilter: VSNode {
    let pipelineState:MTLComputePipelineState
    let paramBuffers:[MTLBuffer]
    
    init(pipelineState:MTLComputePipelineState, buffers:[MTLBuffer]) {
        self.pipelineState = pipelineState
        self.paramBuffers = buffers
    }
        
    func encode(commandBuffer:MTLCommandBuffer, context:VSContext) {
        let encoder = commandBuffer.makeComputeCommandEncoder()
        encoder.setComputePipelineState(pipelineState)
        encoder.setTexture(context.pop().texture, at: 0)
        encoder.setTexture(context.getAndPush().texture, at: 1)
        for (index, buffer) in paramBuffers.enumerated() {
            encoder.setBuffer(buffer, offset: 0, at: 2 + index)
        }
        encoder.dispatchThreadgroups(context.threadGroupCount, threadsPerThreadgroup: context.threadGroupSize)
        encoder.endEncoding()
    }
}
