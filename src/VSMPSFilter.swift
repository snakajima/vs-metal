//
//  VSMPSFilter.swift
//  vs-metal
//
//  Created by SATOSHI NAKAJIMA on 6/22/17.
//  Copyright © 2017 SATOSHI NAKAJIMA. All rights reserved.
//

import Foundation
import MetalPerformanceShaders

/// VSFilter is a concrete implemtation of VSNode prototol, which represents a filter node implemented with a MPS kernel.
struct VSMPSFilter: VSNode {
    private let kernel:MPSUnaryImageKernel

    /// Make a MPS filter object, which conforms to VSNode protocol.
    /// This function is called by VSSCript during the compilation process.
    ///
    /// - Parameters:
    ///   - nodeName: name of the node, which is the name of Metal kernel
    ///   - parameters
    ///   - device: metal device
    /// - Returns: a VSNode object
    static func makeNode(name:String, params:[String:Any], device:MTLDevice) -> VSNode? {
        switch(name) {
        case "gaussian_blur":
            if let sigma = VSScript.floatValues(params: params, key:"sigma"), sigma.count == 1 {
                let kernel = MPSImageGaussianBlur(device: device, sigma: sigma[0])
                return VSMPSFilter(kernel: kernel)
            }
        case "sobel_mps":
            if let weight = VSScript.floatValues(params: params, key:"weight"), weight.count == 3 {
                let kernel = MPSImageSobel(device: device, linearGrayColorTransform: weight)
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
    
    /// Encode appropriate GPU instructions into the command buffer
    ///
    /// - Parameters:
    ///   - commandBuffer: The command buffer to encode to
    ///   - context: the video pipeline context
    /// - Throws: VSContextError.underUnderflow if pop() was called when the stack is empty
    func encode(commandBuffer:MTLCommandBuffer, context:VSContext) {
        let destination = context.get() // must be called before pop
        if let source = context.pop() {
            kernel.encode(commandBuffer: commandBuffer, sourceTexture: source.texture, destinationTexture: destination.texture)
            context.push(texture:destination)
        }
    }
}
