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
    var context:VSContext = VSContext(device: MTLCreateSystemDefaultDevice()!)
    var runtime:VSRuntime?
    
    var reader:AVAssetReader?
    var output:AVAssetReaderTrackOutput?
    var texture:MTLTexture?
    lazy var commandQueue:MTLCommandQueue = self.context.device.makeCommandQueue()
    var writer:AVAssetWriter?
    var input:AVAssetWriterInput?
    var adaptor:AVAssetWriterInputPixelBufferAdaptor?
    var url:URL?

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
                    let track = asset.tracks(withMediaType: AVMediaTypeVideo)[0]
                    let settings:[String:Any] = [kCVPixelBufferPixelFormatTypeKey as String:kCVPixelFormatType_32BGRA]
                    let output = AVAssetReaderTrackOutput(track: track, outputSettings: settings)
                    self.output = output
                    reader.add(output)
                    reader.startReading()
                    
                    let fileManager = FileManager.default
                    guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
                        print("no document directory")
                        return
                    }
                    let url = documentsURL.appendingPathComponent("export.mov")
                    if fileManager.fileExists(atPath: url.path) {
                        try? fileManager.removeItem(at: url)
                    }
                    guard let writer = try? AVAssetWriter(url: url, fileType: AVFileTypeQuickTimeMovie) else {
                        print("failed to create a file", url)
                        return
                    }
                    self.url = url
                    self.writer = writer

                    // https://stackoverflow.com/questions/44797728/recording-a-video-filtered-with-cifilter-is-too-slow
                    /*
                    let compressionSettings: [String: Any] = [
                        AVVideoAverageBitRateKey: NSNumber(value: 20000000),
                        AVVideoMaxKeyFrameIntervalKey: NSNumber(value: 1),
                        AVVideoProfileLevelKey: AVVideoProfileLevelH264Baseline41
                    ]
                    */

                    let videoSettings: [String : Any] = [
                        AVVideoCodecKey  : AVVideoCodecH264,
                        //AVVideoCompressionPropertiesKey: compressionSettings,
                        AVVideoWidthKey  : track.naturalSize.width,
                        AVVideoHeightKey : track.naturalSize.height,
                        //AVVideoScalingModeKey:AVVideoScalingModeResizeAspectFill
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
                } else {
                    print("failed to create asset reader")
                }
            }
        }
    }
    
    private func processNext() {
        guard let reader = self.reader,
            let output = self.output,
            let input = self.input,
            let writer = self.writer,
            let url = self.url else {
                return
        }
        guard reader.status == .reading,
            let sampleBuffer = output.copyNextSampleBuffer(),
            let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            print("Process Complete")
            input.markAsFinished()
            writer.finishWriting {
                print("Finish Writing")
                let sheet = UIActivityViewController(activityItems: [url], applicationActivities: nil)
                if let popover = sheet.popoverPresentationController {
                    popover.barButtonItem = self.btnCamera
                }
                self.present(sheet, animated: true, completion: nil)
            }
            return
        }
        
        let width = CVPixelBufferGetWidth(pixelBuffer), height = CVPixelBufferGetHeight(pixelBuffer)
        var metalTextureFromPixelBuffer:CVMetalTexture? = nil
        let status = CVMetalTextureCacheCreateTextureFromImage(nil, self.textureCache, pixelBuffer, nil,
                                                               self.context.pixelFormat, width, height, 0, &metalTextureFromPixelBuffer)
        guard let metalTexture = metalTextureFromPixelBuffer, status == kCVReturnSuccess else {
            print("VSVS: failed to create texture")
            return
        }
        
        DispatchQueue.main.async {
            self.context.set(sourceImage: metalTexture)
            do {
                let commandBuffer = try self.runtime?.encode(commandBuffer:self.context.makeCommandBuffer(), context:self.context)
                commandBuffer?.addCompletedHandler({ (_) in
                    DispatchQueue.main.async {
                        if let texture = try? self.context.pop() {
                            self.texture = texture.texture
                        }
                        self.context.flush()
                        let time = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
                        self.writeNextFrame(time:time)
                     }
                })
                commandBuffer?.commit()
            } catch {
                print("Got an exception")
            }
        }
    }
    
    private func writeNextFrame(time:CMTime) {
        guard let writer = self.writer,
              let adaptor = self.adaptor,
              let texture = self.texture else {
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
        
        // Use the bytes per row value from the pixel buffer since its stride may be rounded up to be 16-byte aligned
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        let region = MTLRegionMake2D(0, 0, texture.width, texture.height)
        
        texture.getBytes(pixelBufferBytes, bytesPerRow: bytesPerRow, from: region, mipmapLevel: 0)
        
        adaptor.append(pixelBuffer, withPresentationTime: time)
        
        self.processNext()
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



