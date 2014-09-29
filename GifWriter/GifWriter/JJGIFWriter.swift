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
}

@objc class JJGIFWriter {
    
    var delegate : JJGIFWriterDelegate?
    var progress : Float
    var destination : CGImageDestinationRef!
    var images: [UIImage]
    
    init(images:[UIImage], destinationURL:NSURL)
    {
        self.images = images;
        progress = 0;
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
            dispatch_async(dispatch_get_main_queue()) {
                self.progress = Float(index)/Float(frameCount)
            }
            NSThread.sleepForTimeInterval(0.25)
            writeImage(image.CGImage, frameDelay: 0.25);
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
