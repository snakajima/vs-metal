//
//  VSContext.swift
//  vs-metal
//
//  Created by SATOSHI NAKAJIMA on 6/22/17.
//  Copyright © 2017 SATOSHI NAKAJIMA. All rights reserved.
//

import Foundation
import MetalPerformanceShaders

struct VSTexture {
    let texture:MTLTexture
}

class VSContext {
    let device:MTLDevice
    let pixelFormat:MTLPixelFormat
    let threadGroupSize = MTLSizeMake(16,16,1)
    var threadGroupCount = MTLSizeMake(1, 1, 1) // to be filled later
    let nodes:[String:[String:Any]] = {
        let url = Bundle.main.url(forResource: "VSNodes", withExtension: "js")!
        let data = try! Data(contentsOf: url)
        let json = try! JSONSerialization.jsonObject(with: data)
        return json as! [String:[String:Any]]
    }()

    private var width = 1, height = 1 // to be set later
    private var descriptor = MTLTextureDescriptor()
    
    // stack: texture stack for the video pipeline
    // transient: popped textures to be migrated to pool later
    // pool: pool of textures to be reused for stack
    private var stack = [VSTexture]()
    private var pool = [VSTexture]()
    private var transient = [VSTexture]()
    private var source:MTLTexture?
    
    init(device:MTLDevice, pixelFormat:MTLPixelFormat) {
        self.device = device
        self.pixelFormat = pixelFormat
    }
    
    var isEmpty:Bool { return source==nil }
    
    // Special type of push for the video source
    func set(texture:MTLTexture) {
        assert(Thread.current == Thread.main)
        stack.removeAll() // HACK: for now
        source = texture
        
        if texture.width==width && texture.height==height {
            return
        }
        width = texture.width
        height = texture.height
        
        transient.removeAll()
        pool.removeAll()
        
        descriptor.textureType = .type2D
        descriptor.pixelFormat = pixelFormat
        descriptor.width = width
        descriptor.height = height
        descriptor.usage = [.shaderRead, .shaderWrite]

        threadGroupCount.width = (width + threadGroupSize.width - 1) / threadGroupSize.width
        threadGroupCount.height = (height + threadGroupSize.height - 1) / threadGroupSize.height

        //print("VSContext:set", threadGroupCount, texture.usage)
    }
    
    func pop() -> VSTexture {
        if let texture = stack.popLast() {
            transient.append(texture)
            return texture
        }
        return VSTexture(texture:source!)
    }
    
    func push(texture:VSTexture) {
        stack.append(texture)
    }
    
    func flush() {
        pool.append(contentsOf: transient)
        transient.removeAll()
    }
    
    func get() -> VSTexture {
        if let texture = pool.last {
            return texture
        }
        print("VSC:get makeTexture")
        return VSTexture(texture:device.makeTexture(descriptor: descriptor))
    }
    
    func getAndPush() -> VSTexture {
        let texture = get()
        push(texture: texture)
        return texture
    }

    func encode(nodes:[VSNode], commandBuffer:MTLCommandBuffer) {
        assert(Thread.current == Thread.main)
        for node in nodes {
            node.encode(commandBuffer:commandBuffer, context:self)
            self.flush()
        }
    }
}
