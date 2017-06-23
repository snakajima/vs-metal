//
//  VSRenderer.swift
//  vs-metal
//
//  Created by satoshi on 6/21/17.
//  Copyright © 2017 SATOSHI NAKAJIMA. All rights reserved.
//

import Foundation
import MetalKit
import MetalPerformanceShaders

class VSProcessor: NSObject, MTKViewDelegate {
    let context:VSContext
    var nodes:[VSNode]
    var renderer:VSRenderer?
    
    private var commandQueue: MTLCommandQueue?
    
    // width/height are texture's, not view's
    init(context:VSContext, view:MTKView) {
        self.context = context
        nodes = [VSNode]()
        super.init()
        
        nodes.append(
            VSFilter(name: "mono", params: ["weight" : [0.2126, 0.7152, 0.0722] as [Float], "color" : [1.0, 1.0, 0.0, 1.0] as [Float]], context: context))
        //nodes.append(
        //    VSMPSFilter(name: "gaussianblur", params: ["sigma" : [5.0] as [Float]], context: context))
        if let node = context.makeNode(name: "gaussianblur", params: ["sigma" : [5.0] as [Float]]) {
            print("#####", node)
            nodes.append(node)
        }

        renderer = VSRenderer(context:context)
        
        // create a single command queue for rendering to this view
        commandQueue = context.device.makeCommandQueue()

        view.delegate = self
    }

    public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // nothing to do
    }

    public func draw(in view: MTKView) {
        guard let commandQueue = self.commandQueue else {
            print("VSR:draw something is wrong")
            return
        }
        
        if context.isEmpty {
            print("VSS:draw texture not updated")
            return
        }
        let cmCompute:MTLCommandBuffer = {
            let commandBuffer = commandQueue.makeCommandBuffer()
            for node in nodes {
                node.encode(commandBuffer:commandBuffer, context:context)
                context.flush()
            }
            return commandBuffer
        }()

        let texture = context.pop()
        let cmRender:MTLCommandBuffer = {
            let commandBuffer = commandQueue.makeCommandBuffer()
            renderer!.encode(commandBuffer:commandBuffer, texture:texture, view:view)
            return commandBuffer
        }()
        
        cmCompute.commit()
        cmRender.commit()
    }
}
