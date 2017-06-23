//
//  VSNode.swift
//  vs-metal
//
//  Created by SATOSHI NAKAJIMA on 6/22/17.
//  Copyright © 2017 SATOSHI NAKAJIMA. All rights reserved.
//

import Foundation
import MetalPerformanceShaders

protocol VSNode {
    func encode(commandBuffer:MTLCommandBuffer, context:VSContext)
}

extension VSNode {
    static func makeNode(name:String, params paramsIn:[String:Any], context:VSContext) -> VSNode? {
        var params:[String:Any] = {
            var params = [String:Any]()
            if let info = context.nodes[name],
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
        switch(name) {
        case "gaussianblur":
            if let sigma = params["sigma"] as? [Float], sigma.count == 1 {
                let kernel = MPSImageGaussianBlur(device: context.device, sigma: sigma[0])
                return VSMPSFilter(kernel: kernel)
            }
        default:
            break
        }
        return nil
    }
}
