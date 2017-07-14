//
//  VSVideoWriter.swift
//  vs-metal
//
//  Created by SATOSHI NAKAJIMA on 7/13/17.
//  Copyright © 2017 SATOSHI NAKAJIMA. All rights reserved.
//

import Foundation
import AVFoundation

/// The procotol the client of video writer object must conform to.
protocol VSVideoWriterDelegate:NSObjectProtocol {
    /// It signals that a frame was appended as a responce to append(texture:) call.
    ///
    /// - Parameter writer: the video writer object
    func didAppendFrame(writer:VSVideoWriter)
    
    /// It signals that the writing session was finished
    ///
    /// - Parameters:
    ///   - writer: the video writer object
    ///   - url: the url of the video file
    func didFinishWriting(writer:VSVideoWriter, url:URL)
}

/// VSVideWriter is a helper class (non-essential part of VideoShader), which makes it easy
/// to create a video file from a series of timed metal textures.
class VSVideoWriter {
    /// The location of the output file (optional). If it is not specified the default URL 
    /// ("export.mov" file in the user's document holder) will be used.
    public var urlExport:URL?
    
    private weak var delegate:VSVideoWriterDelegate?
    private var writer:AVAssetWriter?
    private var input:AVAssetWriterInput?
    private var adaptor:AVAssetWriterInputPixelBufferAdaptor?
    private static var counter = 0
    
    // Returns export0.mov and export1.mov alternatively so that the new one
    // won't destroy the previous one.
    private static var defaultFileName:String {
        counter += 1
        return "export" + String(counter % 2) + ".mov"
    }
    
    /// Initializer
    ///
    /// - Parameter delegate: the delegate object
    init(delegate:VSVideoWriterDelegate) {
        self.delegate = delegate
    }
    
    /// Prepare the writing session
    ///
    /// - Parameter track: the source track (to extract dimension and transform)
    /// - Returns: true if successfully started
    public func prepare(track:AVAssetTrack) -> Bool {
        return prepare(size: track.naturalSize, transform: track.preferredTransform)
    }
    
    /// Prepare the writing session
    ///
    /// - Parameters:
    ///   - size: size of texture
    ///   - transform: transform
    /// - Returns: true if successfully started
    public func prepare(size:CGSize, transform:CGAffineTransform = .identity) -> Bool {
        if self.urlExport == nil {
            // Use the default URL if not specified by the caller
            let fileManager = FileManager.default
            if let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
                let url = documentsURL.appendingPathComponent(VSVideoWriter.defaultFileName)
                if fileManager.fileExists(atPath: url.path) {
                    try? fileManager.removeItem(at: url)
                }
                self.urlExport = url
            }
        }
        
        guard let urlExport = self.urlExport,
              let writer = try? AVAssetWriter(url: urlExport, fileType: AVFileTypeQuickTimeMovie) else {
            print("failed to create a file", self.urlExport ?? "nil")
            return false
        }
        self.writer = writer
        
        let videoSettings: [String : Any] = [
            AVVideoCodecKey  : AVVideoCodecH264,
            AVVideoWidthKey  : size.width,
            AVVideoHeightKey : size.height,
        ]
        let input = AVAssetWriterInput(mediaType: AVMediaTypeVideo, outputSettings: videoSettings)
        input.transform = transform
        self.input = input
        
        let attrs : [String: Any] = [
            String(kCVPixelBufferPixelFormatTypeKey) : kCVPixelFormatType_32BGRA,
            String(kCVPixelBufferWidthKey) : size.width,
            String(kCVPixelBufferHeightKey) : size.height
        ]
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: input, sourcePixelBufferAttributes: attrs)
        self.adaptor = adaptor
        
        writer.add(input)
        
        return true
    }
    
    /// Set the preferred transform of the video
    ///
    /// - Parameter transform: transform
    public func set(transform:CGAffineTransform) {
        input?.transform = transform
    }
    
    /// Start the recording session
    ///
    /// - Parameter atSourceTime: source time
    public func startSession(atSourceTime:CMTime) {
        writer?.startWriting()
        writer?.startSession(atSourceTime: atSourceTime)
    }
    
    /// Append a metal texture as a frame to the video file.
    /// It wlll call delegate's didWriteFrame after appending the texture asynchronously.
    ///
    /// - Parameters:
    ///   - texture: the metal texture
    ///   - presentationTime: the presentation time
    public func append(texture:MTLTexture?, presentationTime:CMTime) {
        guard let writer = self.writer,
            let texture = texture,
            let input = self.input,
            let adaptor = self.adaptor else {
                return
        }
        
        if !input.isReadyForMoreMediaData {
            print("Input is not ready for more media data. Retry async.")
            DispatchQueue.main.async {
                self.append(texture:texture, presentationTime:presentationTime)
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
        
        adaptor.append(pixelBuffer, withPresentationTime: presentationTime)
        
        self.delegate?.didAppendFrame(writer: self)
    }
    
    /// Finish the writing session. It will call delegate's didFinishWriting asynchronously, after finishing.
    public func finishWriting() {
        if let input = self.input, let writer = self.writer, let url = self.urlExport {
            input.markAsFinished()
            writer.finishWriting {
                self.delegate?.didFinishWriting(writer: self, url: url)
            }
        }
    }
}
