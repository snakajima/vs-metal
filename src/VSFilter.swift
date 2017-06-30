//
//  VSFilter.swift
//  vs-metal
//
//  Created by SATOSHI NAKAJIMA on 6/22/17.
//  Copyright © 2017 SATOSHI NAKAJIMA. All rights reserved.
//

import Foundation
import MetalKit

struct VSFilter: VSNode {
    private let pipelineState:MTLComputePipelineState
    private let paramBuffers:[MTLBuffer]
    private let sourceCount:Int
    
    init(pipelineState:MTLComputePipelineState, buffers:[MTLBuffer], sourceCount:Int) {
        self.pipelineState = pipelineState
        self.paramBuffers = buffers
        self.sourceCount = sourceCount
    }
        
    func encode(commandBuffer:MTLCommandBuffer, destination:VSTexture, context:VSContext) throws {
        let encoder = commandBuffer.makeComputeCommandEncoder()
        encoder.setComputePipelineState(pipelineState)
        for index in 0..<sourceCount {
            encoder.setTexture(try context.pop().texture, at: index)
        }
        encoder.setTexture(destination.texture, at: sourceCount)
        for (index, buffer) in paramBuffers.enumerated() {
            encoder.setBuffer(buffer, offset: 0, at: sourceCount + 1 + index)
        }
        encoder.dispatchThreadgroups(context.threadGroupCount, threadsPerThreadgroup: context.threadGroupSize)
        encoder.endEncoding()
        context.push(texture:destination)
    }
}
