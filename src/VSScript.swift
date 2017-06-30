//
//  VSScript.swift
//  vs-metal
//
//  Created by SATOSHI NAKAJIMA on 6/23/17.
//  Copyright © 2017 SATOSHI NAKAJIMA. All rights reserved.
//

import Foundation
import MetalPerformanceShaders

struct VSScript {
    private static let nodeInfos:[String:[String:Any]] = {
        let url = Bundle.main.url(forResource: "VSNodes", withExtension: "js")!
        let data = try! Data(contentsOf: url)
        let json = try! JSONSerialization.jsonObject(with: data)
        return json as! [String:[String:Any]]
    }()
    
    static func getNodeInfo(name:String) -> [String:Any]? {
        return VSScript.nodeInfos[name]
    }

    private let pipeline:[[String:Any]]
    private let constants:[String:[Float]]
    private let variables:[String:[String:Any]]
    
    init(json:[String:Any], pipeline:[[String:Any]]) {
        self.pipeline = pipeline
        self.constants = json["constants"] as? [String:[Float]] ?? [String:[Float]]()
        self.variables = json["variables"] as? [String:[String:Any]] ?? [String:[String:Any]]()
    }

    static func load(from:URL?) -> VSScript? {
        guard let url = from else {
            return nil
        }
        do {
            let data = try Data(contentsOf: url)
            if let json = try JSONSerialization.jsonObject(with: data) as? [String:Any],
               let pipeline = json["pipeline"] as? [[String:Any]] {
                return VSScript(json:json, pipeline: pipeline)
            }
        } catch {
        }
        return nil
    }
    
    private static func makeNode(name:String, params paramsIn:[String:Any]?, context:VSContext) -> VSNode? {
        guard let info = VSScript.getNodeInfo(name: name) else {
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
        
        if let node = VSControllers.makeNode(name: name) {
            return node
        } else if let node = VSMPSFilter.makeNode(name: name, params: params, context: context) {
            return node
        }

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
        context.updateNamedBuffers(with: self.constants)
        
        var dynamicVariables = [VSDynamicVariable]()
        for (key, params) in self.variables {
            print("key=", key, params)
            if let type = params["type"] as? String {
                switch(type) {
                case "sin":
                    dynamicVariables.append(VSTimer(key: key, params: params))
                default:
                    break
                }
            }
        }
        
        return VSRuntime(nodes:nodes, dynamicVariables:dynamicVariables)
    }
}
