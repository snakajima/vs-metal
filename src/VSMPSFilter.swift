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
    
    init(name:String, context:VSContext) {
        kernel = MPSImageGaussianBlur(device: context.device, sigma: 5.0)
    }

    func encode(commandBuffer:MTLCommandBuffer, context:VSContext) {
        let source = context.pop()
        let destination = context.getAndPush()
        kernel.encode(commandBuffer: commandBuffer, sourceTexture: source, destinationTexture: destination)
    }
}
