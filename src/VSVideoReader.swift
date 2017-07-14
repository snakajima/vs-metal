//
//  VSVideoReader.swift
//  vs-metal
//
//  Created by SATOSHI NAKAJIMA on 7/13/17.
//  Copyright © 2017 SATOSHI NAKAJIMA. All rights reserved.
//

import Foundation
import AVFoundation

/// The procotol the client of video reader object must conform to.
protocol VSVideoReaderDelegate: NSObjectProtocol {
    /// It signals that the reading session has started successfully.
    ///
    /// - Parameters:
    ///   - reader: the video reader object
    ///   - track: the video track to get frames from
    func didStartReading(reader:VSVideoReader, track:AVAssetTrack)

    /// It signals that it failed to start the reading session.
    ///
    /// - Parameter reader: the video reader object
    func didFailToLoad(reader:VSVideoReader)

    /// It presents the frame as the metal texture as a responce to readNextFrame() call.
    ///
    /// - Parameters:
    ///   - reader: the video reader object
    ///   - texture: the metal texture of the frame
    ///   - presentationTime: <#presentationTime description#>
    func didGetFrame(reader:VSVideoReader, texture:MTLTexture, presentationTime:CMTime)

    /// It signals that there is no more frame (end of the track) as a responce to readNextFrame() call.
    ///
    /// - Parameter reader: the video reader object
    func didFinishReading(reader:VSVideoReader)
}

/// VSVideoReader is a helper class (non-essential part of VideoShader), which makes it easy
/// to load a video file and extract each frame as a metal texture (MTLTexture).
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
    
    /// Initializer
    ///
    /// - Parameters:
    ///   - device: metal device
    ///   - pixelFormat: pixel format of the metal texture to extract
    ///   - url: url of the source video file
    ///   - delegate: delegate
    init(device:MTLDevice, pixelFormat:MTLPixelFormat, url:URL, delegate:VSVideoReaderDelegate) {
        self.device = device
        self.pixelFormat = pixelFormat
        self.url = url
        self.delegate = delegate
    }
    
    /// Start the reading session. If it succeeds, it will call delegate's didStartReadring() method asynchronously.
    /// Otherwise, it will call delegate's didFailToLoad() method asychronously.
    public func startReading() {
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
                    self.delegate?.didFailToLoad(reader: self)
                }
            }
        }
    }
    
    /// Extract the next frame. If it succeeds, it will call delegate's didGetFrame() method.
    /// If there is no frame, it will call delegate's didFinishReading() method.
    public func readNextFrame() {
        guard let reader = self.reader,
            let output = self.output else {
                return
        }
        guard reader.status == .reading,
              let sampleBuffer = output.copyNextSampleBuffer(),
              let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
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
