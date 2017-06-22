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

class VSRenderer: NSObject, MTKViewDelegate {
    let context:VSContext
    var filter0:VSFilter?
    var filter1:VSMPSFilter?
    
    // Public properties to be updated by the caller (controller)
    var textureIn:MTLTexture? {
        didSet {
            textureUpdated = true
        }
    }
    
    private var textureOut0:MTLTexture?
    private var textureOut1:MTLTexture?
    private var threadGroupSize = MTLSizeMake(16,16,1)
    private var threadGroupCount = MTLSizeMake(1, 1, 1) // to be filled later

    private var textureUpdated = false
    private var commandQueue: MTLCommandQueue?
    
    private var pipelineState: MTLRenderPipelineState?
    private var psGrayScale: MTLComputePipelineState?
    private var guassian:MPSUnaryImageKernel?
    
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

    // width/height are texture's, not view's
    init(context:VSContext, view:MTKView, width:Int, height:Int) {
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
        
        //
        let kernel = defaultLibrary.makeFunction(name: "grayscaleKernel")!
        psGrayScale = try! context.device.makeComputePipelineState(function: kernel)
        
        let descriptor = MTLTextureDescriptor()
        descriptor.textureType = .type2D
        descriptor.pixelFormat = view.colorPixelFormat
        descriptor.width = width
        descriptor.height = height
        descriptor.usage = [.shaderRead, .shaderWrite]
        textureOut0 = context.device.makeTexture(descriptor: descriptor)
        textureOut1 = context.device.makeTexture(descriptor: descriptor)
        
        guassian = MPSImageGaussianBlur(device: context.device, sigma: 5.0)
        
        threadGroupCount.width = (width + threadGroupSize.width - 1) / threadGroupSize.width
        threadGroupCount.height = (height + threadGroupSize.height - 1) / threadGroupSize.height
        
        print("VSR", threadGroupCount)

        view.delegate = self
    }

    public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // nothing to do
    }

    public func draw(in view: MTKView) {
        guard let renderPassDescriptor = view.currentRenderPassDescriptor,
              let drawable = view.currentDrawable,
              let pipelineState = self.pipelineState,
              let textureIn = self.textureIn,
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
            let encoder = commandBuffer.makeComputeCommandEncoder()
            encoder.setComputePipelineState(psGrayScale!)
            encoder.setTexture(textureIn, at: 0)
            encoder.setTexture(textureOut0, at: 1)
            encoder.dispatchThreadgroups(threadGroupCount, threadsPerThreadgroup: threadGroupSize)
            encoder.endEncoding()

            guassian?.encode(commandBuffer: commandBuffer, sourceTexture: textureOut0!, destinationTexture: textureOut1!)
            return commandBuffer
        }()

        let cmRender:MTLCommandBuffer = {
            let commandBuffer = commandQueue.makeCommandBuffer()
            let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
            encoder.setRenderPipelineState(pipelineState)
            encoder.setVertexBytes(VSRenderer.vertexData, length: dataSize, at: 0)
            encoder.setFragmentTexture(textureOut1, at: 0)
            encoder.drawPrimitives(type: .triangle, vertexStart: 0,
                                   vertexCount: VSRenderer.vertexData.count,
                                   instanceCount: VSRenderer.vertexData.count/3)
            encoder.endEncoding()
            commandBuffer.present(drawable)
            return commandBuffer
        }()
        
        cmCompute.commit()
        cmRender.commit()
    }
}
