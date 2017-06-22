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
    let library:MTLLibrary
    let threadGroupSize = MTLSizeMake(16,16,1)
    var threadGroupCount = MTLSizeMake(1, 1, 1) // to be filled later

    private var descriptor = MTLTextureDescriptor()
    
    // stack: texture stack for the video pipeline
    // transient: popped textures to be migrated to pool later
    // pool: pool of textures to be reused for stack
    private var stack = [MTLTexture]()
    private var pool = [MTLTexture]()
    private var transient = [MTLTexture]()
    
    init() {
        device = MTLCreateSystemDefaultDevice()!
        library = device.newDefaultLibrary()!
    }
    
    func set(width:Int, height:Int, colorPixelFormat:MTLPixelFormat) {
        descriptor.textureType = .type2D
        descriptor.pixelFormat = colorPixelFormat
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
