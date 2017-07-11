//
//  SampleViewController1.swift
//  vs-metal
//
//  Created by SATOSHI NAKAJIMA on 6/20/17.
//  Copyright © 2017 SATOSHI NAKAJIMA. All rights reserved.
//

import UIKit
import MetalKit

class SampleViewController1: UIViewController {
    var context:VSContext = VSContext(device: MTLCreateSystemDefaultDevice()!)
    lazy var session:VSCaptureSession = VSCaptureSession(context: self.context)
    var runtime:VSRuntime?
    lazy var renderer:VSRenderer = VSRenderer(context:self.context)

    override func viewDidLoad() {
        super.viewDidLoad()

        if let mtkView = self.view as? MTKView {
            mtkView.device = context.device
            mtkView.delegate = self
            context.pixelFormat = mtkView.colorPixelFormat
            
            // This is a VideoShader script, which represents a cartoon filter
            let json = [
                "pipeline":[
                    [ "name":"gaussian_blur", "attr":["sigma": 2.0] ],
                    [ "name":"fork" ],
                    [ "name":"gaussian_blur", "attr":["sigma": 2.0] ],
                    [ "name":"toone" ],
                    [ "name":"swap" ],
                    [ "name":"sobel"],
                    [ "name":"canny_edge", "attr":["threshold": 0.19, "thin": 0.50] ],
                    [ "name":"anti_alias" ],
                    [ "name":"alpha" ],
                ]
            ]
            let script = VSScript(json: json)
            runtime = script.compile(context: context)
            
            session.start()
        }
    }
}

extension SampleViewController1 : MTKViewDelegate {
    public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
    
    public func draw(in view: MTKView) {
        if context.hasUpdate {
            try? runtime?.encode(commandBuffer:context.makeCommandBuffer(), context:context).commit()
            renderer.encode(commandBuffer:context.makeCommandBuffer(), view:view, texture: try? context.pop().texture)?.commit()
            context.flush()
        }
    }
}



