//
//  SampleViewController1.swift
//  vs-metal
//
//  Created by SATOSHI NAKAJIMA on 6/20/17.
//  Copyright © 2017 SATOSHI NAKAJIMA. All rights reserved.
//

import UIKit
import AVFoundation
import MetalKit

class SampleViewController1: UIViewController {
    // Public properties to be specified by the callers
    var urlScript:URL?

    // VideoShader properties
    var context:VSContext = VSContext(device: MTLCreateSystemDefaultDevice()!)
    var runtime:VSRuntime!
    lazy var session:VSCaptureSession = VSCaptureSession(context: self.context)
    lazy var renderer:VSRenderer = VSRenderer(context:self.context)

    override func viewDidLoad() {
        super.viewDidLoad()

        if let mtkView = self.view as? MTKView {
            let script = VSScript()
                            .gaussian_blur(sigma: 2.0)
                            .toone()
            runtime = script.compile(context: context)
            context.pixelFormat = mtkView.colorPixelFormat
            mtkView.device = context.device
            mtkView.delegate = self
            session.start()
        }
    }
}

extension SampleViewController1 : MTKViewDelegate {
    public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
    
    public func draw(in view: MTKView) {
        if context.hasUpdate {
            do {
                try context.encode(commandBuffer: context.makeCommandBuffer(), runtime: runtime)
                           .commit()
                try renderer.encode(commandBuffer:context.makeCommandBuffer(), view:view)
                           .commit()
            } catch let error {
                print("#### ERROR #### VSProcessor:draw", error)
            }
            context.flush()
        }
    }
}



