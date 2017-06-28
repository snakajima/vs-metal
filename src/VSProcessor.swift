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
    private var runtime:VSRuntime
    private var debugCounter = 0
    
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
        debugCounter += 1
        if !context.hasUpdate {
            //print("VSS:draw texture not updated", debugCounter)
            return
        }

        do {
            let cmCompute:MTLCommandBuffer = try {
                let commandBuffer = context.commandQueue.makeCommandBuffer()
                try context.encode(runtime: runtime, commandBuffer: commandBuffer)
                return commandBuffer
            }()
            
            let texture = try context.pop()
            let cmRender:MTLCommandBuffer = {
                let commandBuffer = context.commandQueue.makeCommandBuffer()
                renderer.encode(commandBuffer:commandBuffer, texture:texture.texture, view:view)
                return commandBuffer
            }()
            
            cmCompute.commit()
            cmRender.commit()
        } catch let error {
            print("#### ERROR #### VSProcessor:draw", error)
        }
    }
}
