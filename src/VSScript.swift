//
//  VSScript.swift
//  vs-metal
//
//  Created by SATOSHI NAKAJIMA on 6/23/17.
//  Copyright © 2017 SATOSHI NAKAJIMA. All rights reserved.
//

import UIKit
import MetalPerformanceShaders

struct VSScript {
    private let json:[String:Any]
    private init(json:[String:Any]) {
        self.json = json
    }

    var pipeline:[[String:Any]] {
        // pre-validated by make
        return json["pipeline"] as! [[String:Any]]
    }
    
    static func make(url:URL) -> VSScript? {
        do {
            let data = try Data(contentsOf: url)
            if let json = try JSONSerialization.jsonObject(with: data) as? [String:Any],
               let _ = json["pipeline"] as? [[String:Any]] {
                return VSScript(json: json)
            }
        } catch {
        }
        return nil
    }
    
    private static func makeNode(name:String, params paramsIn:[String:Any]?, context:VSContext) -> VSNode? {
        guard let info = context.nodes[name] else {
            print("### VSScript:makeNode Invalid node name", name)
            return nil
        }
        var params = [String:Any]()
        var names = [String]()
        if let attrs = info["attr"] as? [[String:Any]] {
            for attr in attrs {
                if let name=attr["name"] as? String,
                    var defaults=attr["default"] as? [Float] {
                    if let values = paramsIn?[name] as? [Float], values.count <= defaults.count {
                        //print("VSC:makeNode overriding", name)
                        for (index, value) in values.enumerated() {
                            defaults[index] = value
                        }
                    }
                    names.append(name)
                    params[name] = defaults
                }
            }
        }
        //print("VSC:names = ", names)

        switch(name) {
        case "gaussianblur":
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
        case "fork":
            return VSFork()
        case "swap":
            return VSSwap()
        default:
            let buffers = names.map({ (name) -> MTLBuffer in
                let values = params[name] as! [Float]
                let length = MemoryLayout.size(ofValue: values[0]) * values.count
                let buffer = context.device.makeBuffer(length: (length + 15) / 16 * 16, options: .storageModeShared)
                memcpy(buffer.contents(), values, length)
                if let key = paramsIn?[name] as? String {
                    context.registerNamedBuffer(key: key, buffer: buffer)
                }
                return buffer
            })
            let sourceCount = info["sources"] as? Int ?? 1
            guard let kernel = context.device.newDefaultLibrary()!.makeFunction(name: name) else {
                print("### VSScript:makeNode failed to create kernel", name)
                return nil
            }
            do {
                let pipelineState = try context.device.makeComputePipelineState(function: kernel)
                return VSFilter(pipelineState: pipelineState, buffers: buffers, sourceCount:sourceCount)
            } catch {
                print("### VSScript:makeNode failed to create pipeline state", name)
            }
        }
        return nil
    }
    
    func compile(context:VSContext) -> VSRuntime {
        var nodes = [VSNode]()
        for item in self.pipeline {
            if let name=item["name"] as? String {
                if let node = VSScript.makeNode(name: name, params: item["attr"] as? [String:Any], context:context) {
                    nodes.append(node)
                }
            }
        }
        if let constants = json["constants"] as? [String:[Float]] {
            context.updateNamedBuffers(with: constants)
        }
        
        var vars = [VSVariable]()
        if let variables = json["variables"] as? [String:[String:Any]] {
            for (key, params) in variables {
                print("key=", key, params)
                vars.append(VSTimer(key: key, params: params))
            }
        }
        context.variables = vars
        
        return VSRuntime(nodes:nodes)
    }
}
