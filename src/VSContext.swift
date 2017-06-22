//
//  VSContext.swift
//  vs-metal
//
//  Created by SATOSHI NAKAJIMA on 6/22/17.
//  Copyright © 2017 SATOSHI NAKAJIMA. All rights reserved.
//

import UIKit

class VSContext {
    let device:MTLDevice
    let pixelFormat:MTLPixelFormat
    let threadGroupSize = MTLSizeMake(16,16,1)
    var threadGroupCount = MTLSizeMake(1, 1, 1) // to be filled later

    private var width = 1, height = 1 // to be set later
    private var descriptor = MTLTextureDescriptor()
    
    // stack: texture stack for the video pipeline
    // transient: popped textures to be migrated to pool later
    // pool: pool of textures to be reused for stack
    private var stack = [MTLTexture]()
    private var pool = [MTLTexture]()
    private var transient = [MTLTexture]()
    
    init(device:MTLDevice, pixelFormat:MTLPixelFormat) {
        self.device = device
        self.pixelFormat = pixelFormat
    }
    
    func set(width:Int, height:Int) {
        if width==self.width && height==self.height {
            return
        }
        descriptor.textureType = .type2D
        descriptor.pixelFormat = pixelFormat
        descriptor.width = width
        descriptor.height = height
        descriptor.usage = [.shaderRead, .shaderWrite]

        threadGroupCount.width = (width + threadGroupSize.width - 1) / threadGroupSize.width
        threadGroupCount.height = (height + threadGroupSize.height - 1) / threadGroupSize.height
    }
    
    func popTexture() -> MTLTexture {
        let texture = stack.popLast()!
        transient.append(texture)
        return texture
    }
    
    func pushTexture(texture:MTLTexture) {
        stack.append(texture)
    }
    
    func flush() {
        stack.append(contentsOf: transient)
        transient.removeAll()
    }
    
    func getTexture() -> MTLTexture {
        if let texture = pool.last {
            return texture
        }
        return device.makeTexture(descriptor: descriptor)
    }
}
