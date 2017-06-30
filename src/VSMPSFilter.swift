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
    
    init(kernel:MPSUnaryImageKernel) {
        self.kernel = kernel
    }
    
    init(name:String, params paramsIn:[String:Any], context:VSContext) {
        var params:[String:Any] = {
            var params = [String:Any]()
            if let info = VSScript.getNodeInfo(name: name),
                let attrs = info["attr"] as? [[String:Any]] {
                for attr in attrs {
                    if let name=attr["name"] as? String,
                       var defaults=attr["default"] as? [Float] {
                        if let values = paramsIn[name] as? [Float], values.count <= defaults.count {
                            print("overriding", name)
                            for (index, value) in values.enumerated() {
                                defaults[index] = value
                            }
                        }
                        params[name] = defaults
                    }
                }
            }
            return params
        }()
        let sigma = params["sigma"] as! [Float]
        kernel = MPSImageGaussianBlur(device: context.device, sigma: sigma[0])
    }

    func encode(commandBuffer:MTLCommandBuffer, destination:VSTexture, context:VSContext) throws {
        let source = try context.pop()
        kernel.encode(commandBuffer: commandBuffer, sourceTexture: source.texture, destinationTexture: destination.texture)
        context.push(texture:destination)
    }
}
