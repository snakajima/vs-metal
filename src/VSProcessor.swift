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
    private let context:VSContext
    private let renderer:VSRenderer
    private let commandQueue: MTLCommandQueue
    private var nodes:[VSNode]
    
    init(context:VSContext, view:MTKView, script:VSScript) {
        self.context = context
        commandQueue = context.device.makeCommandQueue()
        renderer = VSRenderer(context:context)
        nodes = script.compile(context: context)
        
        super.init()
        view.delegate = self
    }

    public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // nothing to do
    }

    public func draw(in view: MTKView) {
        if context.isEmpty {
            print("VSS:draw texture not updated")
            return
        }
        let cmCompute:MTLCommandBuffer = {
            let commandBuffer = commandQueue.makeCommandBuffer()
            context.encode(nodes: nodes, commandBuffer: commandBuffer)
            return commandBuffer
        }()

        let texture = context.pop()
        let cmRender:MTLCommandBuffer = {
            let commandBuffer = commandQueue.makeCommandBuffer()
            renderer.encode(commandBuffer:commandBuffer, texture:texture.texture, view:view)
            return commandBuffer
        }()
        
        cmCompute.commit()
        cmRender.commit()
    }
}
