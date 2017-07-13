//
//  VSVideoWriter.swift
//  vs-metal
//
//  Created by SATOSHI NAKAJIMA on 7/13/17.
//  Copyright © 2017 SATOSHI NAKAJIMA. All rights reserved.
//

import Foundation
import AVFoundation

enum VSVideoWriterError:Error {
    case failedToLoadSourceAsset
}

protocol VSVideoWriterDelegate:NSObjectProtocol {
    func didWriteFrame(writer:VSVideoWriter)
    func didFinishWriting(writer:VSVideoWriter, url:URL)
}

class VSVideoWriter {
    public var urlExport:URL?
    weak var delegate:VSVideoWriterDelegate?
    
    // For writing
    private var writer:AVAssetWriter?
    private var input:AVAssetWriterInput?
    private var adaptor:AVAssetWriterInputPixelBufferAdaptor?
    
    init(delegate:VSVideoWriterDelegate) {
        self.delegate = delegate
    }
    
    func startWriting(track:AVAssetTrack) -> Bool {
        if self.urlExport == nil {
            // Use the default URL if not specified by the caller
            let fileManager = FileManager.default
            if let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
                let url = documentsURL.appendingPathComponent("export.mov")
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
            AVVideoWidthKey  : track.naturalSize.width,
            AVVideoHeightKey : track.naturalSize.height,
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
        
        return true
    }
    
    func writeFrame(texture:MTLTexture, presentationTime:CMTime) {
        guard let writer = self.writer,
            let input = self.input,
            let adaptor = self.adaptor else {
                return
        }
        
        if !input.isReadyForMoreMediaData {
            print("Input is not ready for more media data. Retry async.")
            DispatchQueue.main.async {
                self.writeFrame(texture:texture, presentationTime:presentationTime)
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
        
        self.delegate?.didWriteFrame(writer: self)
    }
    
    func finishWriting() {
        if let input = self.input, let writer = self.writer, let url = self.urlExport {
            input.markAsFinished()
            writer.finishWriting {
                self.delegate?.didFinishWriting(writer: self, url: url)
            }
        }
    }
}
