//
//  VSMPSFilter.swift
//  vs-metal
//
//  Created by SATOSHI NAKAJIMA on 6/22/17.
//  Copyright © 2017 SATOSHI NAKAJIMA. All rights reserved.
//

import Foundation
import MetalPerformanceShaders

class VSMPSFilter: VSNode {
    let kernel:MPSUnaryImageKernel
    
    init(name:String, params:[String:Any], context:VSContext) {
        let sigma = (params["sigma"] as? Double) ?? 1.0
        kernel = MPSImageGaussianBlur(device: context.device, sigma: Float(sigma))
    }

    func encode(commandBuffer:MTLCommandBuffer, context:VSContext) {
        let source = context.pop()
        let destination = context.getAndPush()
        kernel.encode(commandBuffer: commandBuffer, sourceTexture: source, destinationTexture: destination)
    }
}
