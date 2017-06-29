//
//  VSProcessor.swift
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
    private var runtime:VSRuntime
    
    init(context:VSContext, view:MTKView, script:VSScript) {
        self.context = context
        renderer = VSRenderer(context:context)
        runtime = script.compile(context: context)
        
        super.init()
        view.delegate = self
    }

    public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // nothing to do
    }

    public func draw(in view: MTKView) {
        if !context.hasUpdate {
            return // no update
        }

        do {
            let commandBufferCompute = context.commandQueue.makeCommandBuffer()
            try context.encode(runtime: runtime, commandBuffer: commandBufferCompute)
            commandBufferCompute.commit()
            
            let texture = try context.pop()
            let commandBufferRender = context.commandQueue.makeCommandBuffer()
            renderer.encode(commandBuffer:commandBufferRender, texture:texture.texture, view:view)
            commandBufferRender.commit()
        } catch let error {
            print("#### ERROR #### VSProcessor:draw", error)
        }
        context.flush()
    }
}
