//
//  VSRenderer.swift
//  vs-metal
//
//  Created by SATOSHI NAKAJIMA on 6/22/17.
//  Copyright © 2017 SATOSHI NAKAJIMA. All rights reserved.
//

import Foundation
import MetalKit

class VSRenderer {
    private var pipelineState: MTLRenderPipelineState?
    
    struct VSVertex {
        let position:vector_float2
        let textureCoordinate:vector_float2
    }
    var vertexData = [VSVertex]()
    var dataSize:Int = 0
    
    // width/height are texture's, not view's
    init(context:VSContext) {
        // load vertex & fragment shaders
        let defaultLibrary = context.device.newDefaultLibrary()!
        let vertexProgram = defaultLibrary.makeFunction(name: "basic_vertex")
        let fragmentProgram = defaultLibrary.makeFunction(name: "basic_fragment")

        
        // compile them into a pipeline state object
        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.vertexFunction = vertexProgram
        pipelineStateDescriptor.fragmentFunction = fragmentProgram
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = context.pixelFormat
        pipelineState = try! context.device.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
    }
    
    func encode(commandBuffer:MTLCommandBuffer, texture:MTLTexture, view: MTKView) {
        if dataSize == 0 {
            // Very first time
            let viewSize = view.bounds.size
            let viewRatio = viewSize.height / viewSize.width
            let size = CGSize(width:texture.height, height:texture.width)
            let ratio = size.height / size.width
            var x = 1.0 as Float
            var y = 1.0 as Float
            if viewRatio < ratio {
                // needs to trim width
                x = Float(viewRatio / ratio)
            } else {
                y = Float(ratio / viewRatio)
            }
            self.vertexData = [
                VSVertex(position:[-x, -y], textureCoordinate:[x, 0.0]),
                VSVertex(position:[x,  -y], textureCoordinate:[x, y]),
                VSVertex(position:[-x,  y], textureCoordinate:[0.0, 0.0]),
                VSVertex(position:[x, -y], textureCoordinate:[x, y]),
                VSVertex(position:[x,  y], textureCoordinate:[0.0, y]),
                VSVertex(position:[-x,  y], textureCoordinate:[0.0, 0.0]),
                ]
            self.dataSize = vertexData.count * MemoryLayout.size(ofValue: vertexData[0])
        }
        
        guard let renderPassDescriptor = view.currentRenderPassDescriptor,
            let pipelineState = self.pipelineState,
            let drawable = view.currentDrawable else {
                print("VSR:draw something is wrong")
                return
        }
        let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        encoder.setRenderPipelineState(pipelineState)
        encoder.setVertexBytes(vertexData, length: dataSize, at: 0)
        encoder.setFragmentTexture(texture, at: 0)
        encoder.drawPrimitives(type: .triangle, vertexStart: 0,
                               vertexCount: vertexData.count,
                               instanceCount: vertexData.count/3)
        encoder.endEncoding()
        commandBuffer.present(drawable)
    }
}
