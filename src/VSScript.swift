//
//  VSScript.swift
//  vs-metal
//
//  Created by SATOSHI NAKAJIMA on 6/23/17.
//  Copyright © 2017 SATOSHI NAKAJIMA. All rights reserved.
//

import Foundation
import MetalPerformanceShaders

/// An object represents a VideoShader script, which describes the video pipeline. 
/// It has to be compiled into a VSRuntime object (by calling its compile() method)
/// to process the video. 
class VSScript {
    private static let nodeInfos:[String:[String:Any]] = {
        let url = Bundle.main.url(forResource: "VSNodes", withExtension: "js")!
        let data = try! Data(contentsOf: url)
        let json = try! JSONSerialization.jsonObject(with: data)
        return json as! [String:[String:Any]]
    }()
    
    private static func getNodeInfo(name:String) -> [String:Any]? {
        return VSScript.nodeInfos[name]
    }

    private var pipeline:[[String:Any]]
    private let variables:[String:[Float]]
    private let dynamics:[String:[String:Any]]
    
    /// JSON representation of the VideoShader script, from which an equivalent VSScript object can be created.
    public var json:[String:Any] {
        return [
            "variables":variables,
            "dynamics":dynamics,
            "pipeline":pipeline
        ]
    }
    
    /// Initialize a script
    ///
    /// - Parameter json: a VideoShader script
    init(json:[String:Any]) {
        self.pipeline = json["pipeline"] as? [[String:Any]] ?? [[String:Any]]()
        self.variables = json["variables"] as? [String:[Float]] ?? [String:[Float]]()
        self.dynamics = json["dynamics"] as? [String:[String:Any]] ?? [String:[String:Any]]()
    }
    
    /// Initialize an empty script object
    public init() {
        self.pipeline = [[String:Any]]()
        self.variables = [String:[Float]]()
        self.dynamics = [String:[String:Any]]()
    }
    
    /// Append a node to the script object
    ///
    /// - Parameter node: A node with "name" and optional "attr" properties
    /// - Returns: the script object itself
    public func append(node:[String:Any]) -> VSScript {
        pipeline.append(node)
        return self
    }

    /// Create a script object from the specified script file.
    ///
    /// - Parameter from: the URL of the script file
    /// - Returns: a script object
    public static func load(from:URL?) -> VSScript? {
        guard let url = from else {
            return nil
        }
        do {
            let data = try Data(contentsOf: url)
            if let json = try JSONSerialization.jsonObject(with: data) as? [String:Any] {
                return VSScript(json:json)
            }
        } catch {
        }
        return nil
    }
    
    /// Helper function to process attributes, either in [Float], [Double], Float or Double.
    ///
    /// - Parameters:
    ///   - params: attribute dictionary
    ///   - key: attribute name
    /// - Returns: attribute value in [Float] format
    static func floatValues(params:[String:Any]?, key:String) -> [Float]? {
        if let values = params?[key] as? [Float] {
            return values
        }
        if let values = params?[key] as? [Double] {
            return values.map { Float($0) }
        }
        if let value = params?[key] as? Float {
            return [value]
        }
        if let value = params?[key] as? Double {
            return [Float(value)]
        }
        return nil
    }
    
    private static func makeNodes(nodeName name:String?, params paramsIn:[String:Any]?, item itemIn:[String:Any], context:VSContext) -> [VSNode] {
        guard let nodeName = name else { return [] }

        if nodeName == "repeat" {
            if let count = itemIn["count"] as? Int,
               let nodes = itemIn["nodes"] as? [[String:Any]] {
                let nestedNodes = (nodes.map { (item) -> [VSNode] in
                    return VSScript.makeNodes(nodeName: item["name"] as? String, params: item["attr"] as? [String:Any], item:item, context:context)
                }).flatMap { $0 }
                return Array(1..<count).map({ (_) -> [VSNode] in
                    return nestedNodes
                }).flatMap { $0 }
            }
            print("VSScript: repeat is missing count or nodes")
            return []
        }
        
        guard let info = VSScript.getNodeInfo(name: nodeName) else {
            print("### VSScript:makeNode Invalid node name", nodeName)
            return []
        }
        
        var params = [String:Any]()
        var attributeNames = [String]()
        if let attrs = info["attr"] as? [[String:Any]] {
            for attr in attrs {
                if let attributeName=attr["name"] as? String,
                    var defaults = floatValues(params:attr, key:"default") {
                    if let values = floatValues(params:paramsIn, key:attributeName), values.count <= defaults.count {
                        //print("VSC:makeNode overriding", name)
                        for (index, value) in values.enumerated() {
                            defaults[index] = value
                        }
                    }
                    attributeNames.append(attributeName)
                    params[attributeName] = defaults
                }
            }
        }
        
        // Extract named attributes and create named buffers for them
        let buffers = attributeNames.map({ (name) -> MTLBuffer in
            let values = params[name] as! [Float]
            let length = MemoryLayout.size(ofValue: values[0]) * values.count
            let buffer = context.device.makeBuffer(length: (length + 15) / 16 * 16, options: .storageModeShared)
            memcpy(buffer.contents(), values, length)
            if let key = paramsIn?[name] as? String {
                context.registerNamedBuffer(key: key, buffer: buffer)
            }
            return buffer
        })

        // LATER: pass buffers to VPMPSFilter.makeNode as well
        if let node = VSController.makeNode(name: nodeName) {
            return [node]
        } else if let node = VSMPSFilter.makeNode(name: nodeName, params: params, device: context.device) {
            return [node]
        }
        let sourceCount = info["sources"] as? Int ?? 1
        if let node = VSFilter.makeNode(name: nodeName, buffers: buffers, sourceCount: sourceCount, context: context) {
            return [node]
        }
        return []
    }
    
    /// Generate a runtime from the script and initialize the pipeline context.
    ///
    /// - Parameter context: pipeline context
    /// - Returns: a runtime generated from the script
    public func compile(context:VSContext) -> VSRuntime {
        let nodes = (self.pipeline.map { (item) -> [VSNode] in
            return VSScript.makeNodes(nodeName: item["name"] as? String, params: item["attr"] as? [String:Any], item:item, context:context)
        }).flatMap { $0 }
    
        context.updateNamedBuffers(with: self.variables)
        
        let dynamics = (self.dynamics.map { (key, params) -> VSDynamicVariable? in
            switch(params["type"] as? String) {
            case .some("sin"):
                return VSTimer(key: key, params: params)
            default:
                break
            }
            return nil
        }).flatMap { $0 }
        
        return VSRuntime(nodes:nodes, dynamics:dynamics)
    }
}
