//
//  SampleViewController1.swift
//  vs-metal
//
//  Created by SATOSHI NAKAJIMA on 6/20/17.
//  Copyright © 2017 SATOSHI NAKAJIMA. All rights reserved.
//

import UIKit
import MetalKit
import MobileCoreServices

class SampleViewController3: UIViewController {
    var context:VSContext = VSContext(device: MTLCreateSystemDefaultDevice()!)
    var runtime:VSRuntime?
    lazy var renderer:VSRenderer = VSRenderer(context:self.context)

    override func viewDidLoad() {
        super.viewDidLoad()

        if let mtkView = self.view as? MTKView {
            mtkView.device = context.device
            mtkView.delegate = self
            context.pixelFormat = mtkView.colorPixelFormat
        }
        
        // https://stackoverflow.com/questions/12500408/can-i-use-avfoundation-to-stream-downloaded-video-frames-into-an-opengl-es-textu/12500409#12500409
    }
    
    @IBAction func importMovie(_ sender:UIBarButtonItem) {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        picker.mediaTypes = [kUTTypeMovie as String]
        picker.videoQuality = .typeHigh
        self.present(picker, animated: true, completion: nil)
    }
}

extension SampleViewController3 : UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        print("didFinish")
        self.dismiss(animated: true, completion: nil)
        if let url = info[UIImagePickerControllerMediaURL] {
            print("didFinish", url)
        }
    }
}

extension SampleViewController3 : MTKViewDelegate {
    public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
    
    public func draw(in view: MTKView) {
        if context.hasUpdate {
            try? runtime?.encode(commandBuffer:context.makeCommandBuffer(), context:context).commit()
            try? renderer.encode(commandBuffer:context.makeCommandBuffer(), view:view).commit()
            context.flush()
        }
    }
}



