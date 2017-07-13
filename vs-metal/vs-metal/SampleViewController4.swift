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
    @IBOutlet var btnCamera:UIBarButtonItem!

    // For Reading & Writing
    var reader:VSVideoReader?
    var writer:VSVideoWriter?

    // For processing
    var context:VSContext = VSContext(device: MTLCreateSystemDefaultDevice()!)
    var runtime:VSRuntime?

    // For rendering
    var texture:MTLTexture?
    lazy var commandQueue:MTLCommandQueue = self.context.device.makeCommandQueue()
    lazy var renderer:VSRenderer = VSRenderer(device:self.context.device, pixelFormat:self.context.pixelFormat)

    override func viewDidLoad() {
        super.viewDidLoad()

        if let mtkView = self.view as? MTKView {
            mtkView.device = context.device
            mtkView.delegate = self
            context.pixelFormat = mtkView.colorPixelFormat
            renderer.orientation = .landscapeLeft // it means "do not transform"

            let url = Bundle.main.url(forResource: "sports_light", withExtension: "js")
            if let script = VSScript.load(from: url) {
                runtime = script.compile(context: context)
            }
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
            self.reader = VSVideoReader(device: context.device, pixelFormat: context.pixelFormat, url: url, delegate: self)
            self.reader?.startReading()
        }
    }
}

extension SampleViewController4 : VSVideoReaderDelegate {
    func didStartReading(reader:VSVideoReader, track:AVAssetTrack) {
        self.writer = VSVideoWriter(delegate: self)
        let _ = self.writer?.startWriting(track: track)
        reader.readNextFrame()
    }
    
    func didFailToRead(reader:VSVideoReader) {
        print("Sample4: didFailToRead")
    }

    func didGetFrame(reader:VSVideoReader, texture:MTLTexture, presentationTime:CMTime) {
        self.context.set(texture: texture)
        if let commandBuffer = self.runtime?.encode(commandBuffer:self.context.makeCommandBuffer(), context:self.context) {
            commandBuffer.addCompletedHandler { (_) in
                DispatchQueue.main.async {
                    self.texture = self.context.pop()?.texture // store it for renderer
                    self.context.flush()
                    self.writer?.writeFrame(texture: self.texture, presentationTime: presentationTime)
                }
            }
            commandBuffer.commit()
        }
    }
    
    func didFinishReading(reader:VSVideoReader) {
        writer?.finishWriting()
    }
}

extension SampleViewController4 : VSVideoWriterDelegate {
    func didWriteFrame(writer:VSVideoWriter) {
        reader?.readNextFrame()
    }
    
    func didFinishWriting(writer: VSVideoWriter, url: URL) {
        let sheet = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        if let popover = sheet.popoverPresentationController {
            popover.barButtonItem = self.btnCamera
        }
        self.present(sheet, animated: true, completion: nil)
    }
}

extension SampleViewController4 : MTKViewDelegate {
    public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
    
    public func draw(in view: MTKView) {
        if let texture = self.texture {
            renderer.encode(commandBuffer:commandQueue.makeCommandBuffer(), view:view, texture: texture)?.commit()
        }
    }
}



