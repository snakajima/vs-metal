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
    var filter0:VSNode?
    var filter1:VSNode?
    var renderer:VSRenderer?
    
    private var commandQueue: MTLCommandQueue?
    
    // width/height are texture's, not view's
    init(context:VSContext, view:MTKView) {
        self.context = context
        super.init()
        
        filter0 = VSFilter(name: "grayscaleKernel", context: context)
        filter1 = VSMPSFilter(name: "gaussian", context: context)
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
            filter0!.encode(commandBuffer: commandBuffer, context: context)
            context.flush()
            filter1!.encode(commandBuffer: commandBuffer, context: context)
            context.flush()
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
