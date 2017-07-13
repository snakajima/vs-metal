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

    // For Reading
    var reader:VSVideoReader?
    var texture:MTLTexture?

    // For processing
    var context:VSContext = VSContext(device: MTLCreateSystemDefaultDevice()!)
    var runtime:VSRuntime?

    // For writing
    var writer:AVAssetWriter?
    var input:AVAssetWriterInput?
    var adaptor:AVAssetWriterInputPixelBufferAdaptor?
    var url:URL?

    // For rendering
    lazy var commandQueue:MTLCommandQueue = self.context.device.makeCommandQueue()
    lazy var renderer:VSRenderer = VSRenderer(device:self.context.device, pixelFormat:self.context.pixelFormat)

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
    
    fileprivate func processNext() {
        reader?.readNextFrame()
    }
    
    fileprivate func writeNextFrame(time:CMTime) {
        guard let writer = self.writer,
              let input = self.input,
              let adaptor = self.adaptor,
              let texture = self.texture else {
                return
        }
        
        if !input.isReadyForMoreMediaData {
            print("Input is not ready for more media data. Retry async.")
            DispatchQueue.main.async {
                self.writeNextFrame(time: time)
            }
            return
        }
        
        guard let pixelBufferPool = adaptor.pixelBufferPool else {
            print("Pixel buffer asset writer input did not have a pixel buffer pool available; cannot retrieve frame")
            return
        }
        
        var newPixelBuffer: CVPixelBuffer? = nil
        let status  = CVPixelBufferPoolCreatePixelBuffer(nil, pixelBufferPool, &newPixelBuffer)
        guard let pixelBuffer = newPixelBuffer, status == kCVReturnSuccess else {
            print("Could not get pixel buffer from asset writer input; dropping frame...")
            return
        }
        
        CVPixelBufferLockBaseAddress(pixelBuffer, [])
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, []) }
        let pixelBufferBytes = CVPixelBufferGetBaseAddress(pixelBuffer)!
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        let region = MTLRegionMake2D(0, 0, texture.width, texture.height)
        texture.getBytes(pixelBufferBytes, bytesPerRow: bytesPerRow, from: region, mipmapLevel: 0)
        
        adaptor.append(pixelBuffer, withPresentationTime: time)
        
        self.processNext()
    }
}

extension SampleViewController4 : VSVideoReaderDelegate {
    func didStartReading(reader:VSVideoReader, track:AVAssetTrack) {
        let fileManager = FileManager.default
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("no document directory")
            return
        }
        let url = documentsURL.appendingPathComponent("export.mov")
        if fileManager.fileExists(atPath: url.path) {
            try? fileManager.removeItem(at: url)
        }
        self.url = url
        
        guard let writer = try? AVAssetWriter(url: url, fileType: AVFileTypeQuickTimeMovie) else {
            print("failed to create a file", url)
            return
        }
        self.writer = writer
        
        /* no need to specify the compression settings
         let compressionSettings: [String: Any] = [
         AVVideoAverageBitRateKey: NSNumber(value: 20000000),
         AVVideoMaxKeyFrameIntervalKey: NSNumber(value: 1),
         AVVideoProfileLevelKey: AVVideoProfileLevelH264Baseline41
         ]
         */
        
        let videoSettings: [String : Any] = [
            AVVideoCodecKey  : AVVideoCodecH264,
            AVVideoWidthKey  : track.naturalSize.width,
            AVVideoHeightKey : track.naturalSize.height,
            //AVVideoCompressionPropertiesKey: compressionSettings,
        ]
        let input = AVAssetWriterInput(mediaType: AVMediaTypeVideo, outputSettings: videoSettings)
        input.transform = track.preferredTransform
        self.input = input
        
        let attrs : [String: Any] = [
            String(kCVPixelBufferPixelFormatTypeKey) : kCVPixelFormatType_32BGRA,
            String(kCVPixelBufferWidthKey) : track.naturalSize.width,
            String(kCVPixelBufferHeightKey) : track.naturalSize.height
        ]
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: input, sourcePixelBufferAttributes: attrs)
        self.adaptor = adaptor
        
        writer.add(input)
        writer.startWriting()
        writer.startSession(atSourceTime: kCMTimeZero)
        
        self.processNext()
    }
    func didFailToRead(reader:VSVideoReader) {
        
    }
    func didGetFrame(reader:VSVideoReader, texture:MTLTexture, presentationTime:CMTime) {
        self.context.set(texture: texture)
        do {
            let commandBuffer = try self.runtime?.encode(commandBuffer:self.context.makeCommandBuffer(), context:self.context)
            commandBuffer?.addCompletedHandler({ (_) in
                DispatchQueue.main.async {
                    if let texture = try? self.context.pop() {
                        self.texture = texture.texture
                    }
                    self.context.flush()
                    self.writeNextFrame(time:presentationTime)
                }
            })
            commandBuffer?.commit()
        } catch {
            print("Got an exception")
        }
    }
    func didFinishReading(reader:VSVideoReader) {
        if let url = self.url, let input = self.input, let writer = self.writer {
            input.markAsFinished()
            writer.finishWriting {
                print("Finish Writing")
                let sheet = UIActivityViewController(activityItems: [url], applicationActivities: nil)
                if let popover = sheet.popoverPresentationController {
                    popover.barButtonItem = self.btnCamera
                }
                self.present(sheet, animated: true, completion: nil)
            }
        }
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



