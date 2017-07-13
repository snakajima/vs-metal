//
//  VSVideoReader.swift
//  vs-metal
//
//  Created by SATOSHI NAKAJIMA on 7/13/17.
//  Copyright © 2017 SATOSHI NAKAJIMA. All rights reserved.
//

import Foundation
import AVFoundation

protocol VSVideoReaderDelegate: NSObjectProtocol {
    func didStartReading(reader:VSVideoReader, track:AVAssetTrack)
    func didFailToRead(reader:VSVideoReader)
    func didGetFrame(reader:VSVideoReader, texture:MTLTexture, presentationTime:CMTime)
    func didFinishReading(reader:VSVideoReader)
}

class VSVideoReader {
    private let device:MTLDevice
    private let pixelFormat:MTLPixelFormat
    private let url:URL
    private weak var delegate:VSVideoReaderDelegate?
    private var reader:AVAssetReader?
    private var output:AVAssetReaderTrackOutput?

    private lazy var textureCache:CVMetalTextureCache = {
        var cache:CVMetalTextureCache? = nil
        CVMetalTextureCacheCreate(nil, nil, self.device, nil, &cache)
        return cache!
    }()
    
    init(device:MTLDevice, pixelFormat:MTLPixelFormat, url:URL, delegate:VSVideoReaderDelegate) {
        self.device = device
        self.pixelFormat = pixelFormat
        self.url = url
        self.delegate = delegate
    }
    
    func startReading() {
        let asset = AVURLAsset(url: url)
        asset.loadValuesAsynchronously(forKeys: ["tracks"]) {
            DispatchQueue.main.async {
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
                    self.delegate?.didStartReading(reader:self, track:track)
                } else {
                    self.delegate?.didFailToRead(reader: self)
                }
            }
        }
    }
    
    func readNextFrame() {
        guard let reader = self.reader,
            let output = self.output else {
                return
        }
        guard reader.status == .reading,
              let sampleBuffer = output.copyNextSampleBuffer(),
              let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            print("VSVideoReader: Process Complete")
            self.delegate?.didFinishReading(reader: self)
            return
        }
        
        let time = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        let width = CVPixelBufferGetWidth(pixelBuffer), height = CVPixelBufferGetHeight(pixelBuffer)
        var metalTextureFromPixelBuffer:CVMetalTexture? = nil
        let status = CVMetalTextureCacheCreateTextureFromImage(nil, self.textureCache, pixelBuffer, nil,
                                                               pixelFormat, width, height, 0, &metalTextureFromPixelBuffer)
        guard let metalTexture = metalTextureFromPixelBuffer, status == kCVReturnSuccess else {
            print("VSVideoReader: Failed to create texture")
            return
        }
        guard let texture = CVMetalTextureGetTexture(metalTexture) else {
            print("VSVideoReader: Failed to get texture")
            return
        }
        self.delegate?.didGetFrame(reader: self, texture: texture, presentationTime: time)
    }
}
