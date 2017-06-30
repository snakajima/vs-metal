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
