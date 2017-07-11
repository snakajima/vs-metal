//
//  SampleViewController4.swift
//  vs-metal
//
//  Created by SATOSHI NAKAJIMA on 6/20/17.
//  Copyright © 2017 SATOSHI NAKAJIMA. All rights reserved.
//

import UIKit
import MetalKit
import MobileCoreServices
import AVFoundation

class SampleViewController4: UIViewController {
    var context:VSContext = VSContext(device: MTLCreateSystemDefaultDevice()!)
    var runtime:VSRuntime?
    
    var reader:AVAssetReader?
    var output:AVAssetReaderTrackOutput?

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
            renderer.orientation = .landscapeLeft // it means "do not transform"

            // This is an alternative way to create a script object (Beta)
            let script = VSScript()
                .mono()
            runtime = script.compile(context: context)
        }
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

extension SampleViewController4 : UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        self.dismiss(animated: true, completion: nil)
        if let url = info[UIImagePickerControllerMediaURL] as? URL {
            //print("didFinish", url)
            // https://stackoverflow.com/questions/12500408/can-i-use-avfoundation-to-stream-downloaded-video-frames-into-an-opengl-es-textu/12500409#12500409
            let asset = AVURLAsset(url: url)
            asset.loadValuesAsynchronously(forKeys: ["tracks"]) {
                let status = asset.statusOfValue(forKey: "tracks", error: nil)
                if status == AVKeyValueStatus.loaded,
                   let reader = try? AVAssetReader(asset: asset) {
                    self.reader = reader
                    let tracks = asset.tracks(withMediaType: AVMediaTypeVideo)
                    let settings:[String:Any] = [kCVPixelBufferPixelFormatTypeKey as String:kCVPixelFormatType_32BGRA]
                    let output = AVAssetReaderTrackOutput(track: tracks[0], outputSettings: settings)
                    self.output = output
                    reader.add(output)
                    reader.startReading()
                    self.processNext()
                } else {
                    print("failed to create asset reader")
                }
            }
        }
    }
    
    func processNext() {
        guard let reader = self.reader,
            let output = self.output else {
                return
        }
        if reader.status == .reading,
            let sampleBuffer = output.copyNextSampleBuffer(),
            let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
            let width = CVPixelBufferGetWidth(pixelBuffer), height = CVPixelBufferGetHeight(pixelBuffer)
            var metalTexture:CVMetalTexture? = nil
            let status = CVMetalTextureCacheCreateTextureFromImage(nil, self.textureCache, pixelBuffer, nil,
                                                                   self.context.pixelFormat, width, height, 0, &metalTexture)
            if let metalTexture = metalTexture, status == kCVReturnSuccess {
                DispatchQueue.main.async {
                    self.context.set(sourceImage: metalTexture)
                }
            } else {
                print("VSVS: failed to create texture")
            }
        } else {
            print("Process Complete")
        }
    }
}

extension SampleViewController4 : MTKViewDelegate {
    public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
    
    public func draw(in view: MTKView) {
        if context.hasUpdate {
            try? runtime?.encode(commandBuffer:context.makeCommandBuffer(), context:context).commit()
            if let commandBuffer = try? renderer.encode(commandBuffer:context.makeCommandBuffer(), view:view) {
                commandBuffer.addCompletedHandler({ (_) in
                    self.processNext()
                })
                commandBuffer.commit()
            }
            context.flush()
        }
    }
}



