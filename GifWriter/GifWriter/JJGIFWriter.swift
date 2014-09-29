//
//  JJGIFWriter.swift
//  
//
//  Created by Gustavo Barcena on 9/9/14.
//
//

import UIKit
import MobileCoreServices
import ImageIO

@objc protocol JJGIFWriterDelegate {
    func didStartWritingGIF(writer: JJGIFWriter)
    func didEndWritingGIF(writer: JJGIFWriter)
    
    @objc(didWriteImageWithWriter:atFrameIndex:)
    optional func didWriteImage(writer: JJGIFWriter, atFrameIndex frameIndex: Int)
}

class JJGIFWriter : NSObject {
    
    var delegate : JJGIFWriterDelegate?
    dynamic var progress : Float
    var destination : CGImageDestinationRef!
    var images: [UIImage]
    
    init(images:[UIImage], destinationURL:NSURL)
    {
        self.images = images;
        progress = 0
        super.init()
        var fileProperties = self.gifProperties()
        self.destination = CGImageDestinationCreateWithURL(destinationURL, kUTTypeGIF, UInt(self.images.count), nil)
        CGImageDestinationSetProperties(self.destination, fileProperties)
    }
    
    func makeGIF()
    {
        var frameCount = self.images.count
        dispatch_async(dispatch_get_main_queue()) {
            self.progress = 0
            self.delegate?.didStartWritingGIF(self)
        }
        for (index, image) in enumerate(images)
        {
            NSThread.sleepForTimeInterval(0.25)
            writeImage(image.CGImage, frameDelay: 0.25);
            dispatch_async(dispatch_get_main_queue()) {
                self.progress = Float(index)/Float(frameCount)
                self.delegate?.didWriteImage?(self, atFrameIndex: index)
            }
        }
        endWrite();
        dispatch_async(dispatch_get_main_queue()) {
            self.progress = 1
            self.delegate?.didEndWritingGIF(self)
        }
    }
    
    private func writeImage(image:CGImage, frameDelay : NSTimeInterval)
    {
        var frameProperties = self.frameProperties(frameDelay);
        CGImageDestinationAddImage(self.destination, image, frameProperties);
    }
    
    private func endWrite()
    {
        CGImageDestinationFinalize(self.destination)
    }
    
    // Mark: Helpers
    
    private func frameProperties(frameDelay:NSTimeInterval) -> CFDictionary
    {
        var dict = [kCGImagePropertyGIFDelayTime:frameDelay]
        return [kCGImagePropertyGIFDictionary:dict]
    }
    
    private func gifProperties() -> CFDictionary
    {
        var dict = [kCGImagePropertyGIFLoopCount:0];
        return [kCGImagePropertyGIFDictionary:dict]
    }
}
