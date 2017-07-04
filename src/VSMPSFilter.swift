//
//  VSMPSFilter.swift
//  vs-metal
//
//  Created by SATOSHI NAKAJIMA on 6/22/17.
//  Copyright © 2017 SATOSHI NAKAJIMA. All rights reserved.
//

import Foundation
import MetalPerformanceShaders

struct VSMPSFilter: VSNode {
    private let kernel:MPSUnaryImageKernel

    static func makeNode(name:String, params:[String:Any], context:VSContext) -> VSNode? {
        switch(name) {
        case "gaussian_blur":
            if let sigma = params["sigma"] as? [Float], sigma.count == 1 {
                let kernel = MPSImageGaussianBlur(device: context.device, sigma: sigma[0])
                return VSMPSFilter(kernel: kernel)
            }
        case "sobel_mps":
            if let weight = params["weight"] as? [Float], weight.count == 3 {
                let kernel = MPSImageSobel(device: context.device, linearGrayColorTransform: weight)
                return VSMPSFilter(kernel: kernel)
            }
        /*
         case "pyramid":
         if let weight = params["weight"] as? [Float], weight.count == 3 {
         let kernel = MPSImagePyramid(device: device)
         return VSMPSFilter(kernel: kernel)
         }
         */
        case "laplacian":
            let kernel = MPSImageLaplacian()
            return VSMPSFilter(kernel: kernel)
        default:
            break
        }
        return nil
    }
    
    private init(kernel:MPSUnaryImageKernel) {
        self.kernel = kernel
    }
    
    func encode(commandBuffer:MTLCommandBuffer, context:VSContext) throws {
        let source = try context.pop()
        let destination = context.getDestination()
        kernel.encode(commandBuffer: commandBuffer, sourceTexture: source.texture, destinationTexture: destination.texture)
        context.push(texture:destination)
    }
}
