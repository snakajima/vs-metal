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
    let params:[String:Any]
    
    init(name:String, params:[String:Any], context:VSContext) {
        self.params = params
        let kernel = context.device.newDefaultLibrary()!.makeFunction(name: name)!
        pipelineState = try! context.device.makeComputePipelineState(function: kernel)
    }
    
    func encode(commandBuffer:MTLCommandBuffer, context:VSContext) {
        let encoder = commandBuffer.makeComputeCommandEncoder()
        encoder.setComputePipelineState(pipelineState)
        encoder.setTexture(context.pop(), at: 0)
        encoder.setTexture(context.getAndPush(), at: 1)
        let weight:[Float] = [0.2126, 0.7152, 0.0722, 0.0] // must have an extra float (alignment?)
        encoder.setBytes(weight, length: MemoryLayout.size(ofValue: weight[0]) * weight.count, at: 2)
        encoder.dispatchThreadgroups(context.threadGroupCount, threadsPerThreadgroup: context.threadGroupSize)
        encoder.endEncoding()
    }
}
