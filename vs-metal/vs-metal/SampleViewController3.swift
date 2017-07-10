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
import AVFoundation

class SampleViewController3: UIViewController {
    var context:VSContext = VSContext(device: MTLCreateSystemDefaultDevice()!)
    var runtime:VSRuntime?
    var output:AVPlayerItemVideoOutput?
    var playerItem:AVPlayerItem?
    var player:AVPlayer?
    lazy var renderer:VSRenderer = VSRenderer(context:self.context)
    fileprivate lazy var textureCache:CVMetalTextureCache = {
        var cache:CVMetalTextureCache? = nil
        CVMetalTextureCacheCreate(nil, nil, self.context.device, nil, &cache)
        return cache!
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        if let mtkView = self.view as? MTKView {
            mtkView.device = context.device
            mtkView.delegate = self
            context.pixelFormat = mtkView.colorPixelFormat
        }
        // This is an alternative way to create a script object (Beta)
        let script = VSScript()
            .previous()
            .color_tracker(red: 1.0, green: 1.0, blue: 0.12, ratio: 0.95, range: 0.34..<0.80)
            .fork()
        runtime = script.compile(context: context)
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
        self.dismiss(animated: true, completion: nil)
        if let url = info[UIImagePickerControllerMediaURL] as? URL {
            //print("didFinish", url)
            // https://stackoverflow.com/questions/12500408/can-i-use-avfoundation-to-stream-downloaded-video-frames-into-an-opengl-es-textu/12500409#12500409
            let asset = AVURLAsset(url: url)
            asset.loadValuesAsynchronously(forKeys: ["tracks"]) {
                let status = asset.statusOfValue(forKey: "tracks", error: nil)
                if status == AVKeyValueStatus.loaded {
                    //print("didFinish, loaded")
                    let settings:[String:Any] = [kCVPixelBufferPixelFormatTypeKey as String:kCVPixelFormatType_32BGRA]
                    self.output = AVPlayerItemVideoOutput(outputSettings: settings)
                    self.playerItem = AVPlayerItem(asset: asset)
                    self.playerItem!.add(self.output!)
                    self.player = AVPlayer(playerItem: self.playerItem!)
                    self.player!.addPeriodicTimeObserver(forInterval: CMTime(seconds:1.0/30.0, preferredTimescale:600), queue: DispatchQueue.main, using: { (time) in
                        //print("time", time)
                        guard let pixelBuffer = self.output?.copyPixelBuffer(forItemTime: self.playerItem!.currentTime(), itemTimeForDisplay: nil) else {
                            print("failed to copy pixel buffer", time)
                            return
                        }
                        
                        let width = CVPixelBufferGetWidth(pixelBuffer), height = CVPixelBufferGetHeight(pixelBuffer)
                        var metalTexture:CVMetalTexture? = nil
                        let status = CVMetalTextureCacheCreateTextureFromImage(nil, self.textureCache, pixelBuffer, nil,
                                                                               self.context.pixelFormat, width, height, 0, &metalTexture)
                        if let metalTexture = metalTexture, status == kCVReturnSuccess {
                            self.context.set(sourceImage: metalTexture)
                        } else {
                            print("VSVS: failed to create texture")
                        }
                        
                    })
                    self.player!.play()
                }
            }
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



