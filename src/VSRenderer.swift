//
//  VSRenderer.swift
//  vs-metal
//
//  Created by satoshi on 6/21/17.
//  Copyright © 2017 SATOSHI NAKAJIMA. All rights reserved.
//

import UIKit
import MetalKit

class VSRenderer: NSObject, MTKViewDelegate {
    var texture:CVMetalTexture? {
        didSet {
            textureUpdated = true
        }
    }

    private var pipelineState: MTLRenderPipelineState?
    private var commandQueue: MTLCommandQueue?
    private var textureUpdated = false
    
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
    let dataSize = VSRenderer.vertexData.count * MemoryLayout.size(ofValue: VSRenderer.vertexData[0])

    init(view:MTKView) {
        super.init()
        
        if let device = view.device {
            // create a single command queue for rendering to this view
            commandQueue = device.makeCommandQueue()

            // load vertex & fragment shaders
            let defaultLibrary = device.newDefaultLibrary()!
            let vertexProgram = defaultLibrary.makeFunction(name: "basic_vertex")
            let fragmentProgram = defaultLibrary.makeFunction(name: "basic_fragment")

            // compile them into a pipeline state object
            let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
            pipelineStateDescriptor.vertexFunction = vertexProgram
            pipelineStateDescriptor.fragmentFunction = fragmentProgram
            pipelineStateDescriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat
            pipelineState = try! device.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
        }
        view.delegate = self
    }

    public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // nothing to do
    }

    public func draw(in view: MTKView) {
        guard let renderPassDescriptor = view.currentRenderPassDescriptor,
              let drawable = view.currentDrawable,
              let pipelineState = self.pipelineState,
              let texture = self.texture,
              let commandBuffer = commandQueue?.makeCommandBuffer() else {
            print("VSR:draw something is wrong")
            return
        }
        
        if !textureUpdated {
            print("texture not updated")
            return
        }

        let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        encoder.setRenderPipelineState(pipelineState)
        encoder.setVertexBytes(VSRenderer.vertexData, length: dataSize, at: 0)
        encoder.setFragmentTexture(CVMetalTextureGetTexture(texture), at: 0)
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6, instanceCount: 2)
        encoder.endEncoding()
        
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}
