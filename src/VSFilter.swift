//
//  VSFilter.swift
//  vs-metal
//
//  Created by SATOSHI NAKAJIMA on 6/22/17.
//  Copyright © 2017 SATOSHI NAKAJIMA. All rights reserved.
//

import UIKit

class VSFilter {
    let pipelineState:MTLComputePipelineState
    init(name:String, context:VSContext) {
        let kernel = context.device.newDefaultLibrary()!.makeFunction(name: name)!
        pipelineState = try! context.device.makeComputePipelineState(function: kernel)
    }
    
    func encode(commandBuffer:MTLCommandBuffer, context:VSContext) {
        let encoder = commandBuffer.makeComputeCommandEncoder()
        encoder.setComputePipelineState(pipelineState)
        encoder.setTexture(context.popTexture(), at: 0)
        encoder.setTexture(context.getAndPushTexture(), at: 1)
        encoder.dispatchThreadgroups(context.threadGroupCount, threadsPerThreadgroup: context.threadGroupSize)
        encoder.endEncoding()
    }
}
