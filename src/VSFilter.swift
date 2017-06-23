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
    
    init(name:String, params:[String:Any], context:VSContext) {
        //print(info)
        let kernel = context.device.newDefaultLibrary()!.makeFunction(name: name)!
        pipelineState = try! context.device.makeComputePipelineState(function: kernel)

        var buffers = [MTLBuffer]()
        if let info = context.nodes[name],
            let attrs = info["attr"] as? [[String:Any]] {
            for attr in attrs {
                if let name=attr["name"] as? String,
                   var defaults=attr["default"] as? [Float] {
                    //let weight:[Float] = [1.0, 0.0, 0.0] //[0.2126, 0.7152, 0.0722]
                    let length = MemoryLayout.size(ofValue: defaults[0]) * defaults.count
                    let buffer = context.device.makeBuffer(length: (length + 15) / 16 * 16, options: .storageModeShared)
                    if let values = params[name] as? [Float], values.count <= defaults.count {
                        print("overriding", name)
                        for (index, value) in values.enumerated() {
                            defaults[index] = value
                        }
                    }
                    memcpy(buffer.contents(), defaults, length)
                    buffers.append(buffer)
                }
            }
        }
        
        paramBuffers = buffers
    }
    
    func encode(commandBuffer:MTLCommandBuffer, context:VSContext) {
        let encoder = commandBuffer.makeComputeCommandEncoder()
        encoder.setComputePipelineState(pipelineState)
        encoder.setTexture(context.pop(), at: 0)
        encoder.setTexture(context.getAndPush(), at: 1)
        for (index, buffer) in paramBuffers.enumerated() {
            encoder.setBuffer(buffer, offset: 0, at: 2 + index)
        }
        encoder.dispatchThreadgroups(context.threadGroupCount, threadsPerThreadgroup: context.threadGroupSize)
        encoder.endEncoding()
    }
}
