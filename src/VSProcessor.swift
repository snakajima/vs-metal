//
//  VSRenderer.swift
//  vs-metal
//
//  Created by satoshi on 6/21/17.
//  Copyright © 2017 SATOSHI NAKAJIMA. All rights reserved.
//

import UIKit
import MetalKit
import MetalPerformanceShaders

class VSProcessor: NSObject, MTKViewDelegate {
    let context:VSContext
    var filter0:VSFilter?
    var filter1:VSMPSFilter?
    
    private var commandQueue: MTLCommandQueue?
    
    private var pipelineState: MTLRenderPipelineState?
    
    struct VSVertex {
        let position:vector_float2
        let textureCoordinate:vector_float2
    }
    static let vertexData:[VSVertex] = [
        VSVertex(position:[-1.0, -1.0], textureCoordinate:[1.0, 0.0]),
        VSVertex(position:[1.0,  -1.0], textureCoordinate:[1.0, 1.0]),
        VSVertex(position:[-1.0,  1.0], textureCoordinate:[0.0, 0.0]),
        VSVertex(position:[1.0, -1.0], textureCoordinate:[1.0, 1.0]),
        VSVertex(position:[1.0,  1.0], textureCoordinate:[0.0, 1.0]),
        VSVertex(position:[-1.0,  1.0], textureCoordinate:[0.0, 0.0]),
    ]
    let dataSize = VSProcessor.vertexData.count * MemoryLayout.size(ofValue: VSProcessor.vertexData[0])

    // width/height are texture's, not view's
    init(context:VSContext, view:MTKView) {
        self.context = context
        super.init()
        
        filter0 = VSFilter(name: "grayscaleKernel", context: context)
        filter1 = VSMPSFilter(name: "gaussian", context: context)
        
        // create a single command queue for rendering to this view
        commandQueue = context.device.makeCommandQueue()

        // load vertex & fragment shaders
        let defaultLibrary = context.device.newDefaultLibrary()!
        let vertexProgram = defaultLibrary.makeFunction(name: "basic_vertex")
        let fragmentProgram = defaultLibrary.makeFunction(name: "basic_fragment")

        // compile them into a pipeline state object
        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.vertexFunction = vertexProgram
        pipelineStateDescriptor.fragmentFunction = fragmentProgram
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat
        pipelineState = try! context.device.makeRenderPipelineState(descriptor: pipelineStateDescriptor)

        view.delegate = self
    }

    public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // nothing to do
    }

    public func draw(in view: MTKView) {
        guard let renderPassDescriptor = view.currentRenderPassDescriptor,
              let drawable = view.currentDrawable,
              let pipelineState = self.pipelineState,
              let commandQueue = self.commandQueue else {
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
            let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
            encoder.setRenderPipelineState(pipelineState)
            encoder.setVertexBytes(VSProcessor.vertexData, length: dataSize, at: 0)
            encoder.setFragmentTexture(texture, at: 0)
            encoder.drawPrimitives(type: .triangle, vertexStart: 0,
                                   vertexCount: VSProcessor.vertexData.count,
                                   instanceCount: VSProcessor.vertexData.count/3)
            encoder.endEncoding()
            commandBuffer.present(drawable)
            return commandBuffer
        }()
        
        cmCompute.commit()
        cmRender.commit()
    }
}
