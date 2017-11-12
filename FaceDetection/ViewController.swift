//
//  ViewController.swift
//  FaceDetection
//
//  Created by arabian9ts on 2017/11/12.
//  Copyright © 2017年 arabian9ts. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController,UIGestureRecognizerDelegate,AVCaptureVideoDataOutputSampleBufferDelegate  {
    let captureSession = AVCaptureSession()
    let videoDevice = AVCaptureDevice.default(for: AVMediaType.video)
    var videoOutput = AVCaptureVideoDataOutput()
    var hideView = UIView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        do {
            let captureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: AVMediaType.video, position: .front)
            let videoInput: AVCaptureInput = try AVCaptureDeviceInput(device: captureDevice!) as AVCaptureInput
            self.captureSession.addInput(videoInput)
        } catch let error as NSError {
            print(error)
        }
        
        self.videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String : Int(kCVPixelFormatType_32BGRA)]
        
        let queue = DispatchQueue.main
        self.videoOutput.setSampleBufferDelegate(self, queue: queue)
        self.videoOutput.alwaysDiscardsLateVideoFrames = true
        
        self.captureSession.addOutput(self.videoOutput)
        
        let videoLayer : AVCaptureVideoPreviewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession) 
        videoLayer.frame = self.view.bounds
        videoLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        
        self.view.layer.addSublayer(videoLayer)
        
        for connection in self.videoOutput.connections {
            if connection.isVideoOrientationSupported {
                connection.videoOrientation = AVCaptureVideoOrientation.portrait
            }
        }
        hideView = UIView(frame: self.view.bounds)
        self.view.addSubview(hideView)
        self.captureSession.startRunning()
    }
    
    
    func imageFromSampleBuffer(sampleBuffer: CMSampleBuffer) -> UIImage {
        let imageBuffer: CVImageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
        CVPixelBufferLockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: 0))
        let baseAddress = CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer)
        let width = CVPixelBufferGetWidth(imageBuffer)
        let height = CVPixelBufferGetHeight(imageBuffer)
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = (CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue)
        let context = CGContext(data: baseAddress, width: width, height: height, bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo)
        let imageRef = context!.makeImage()
        
        CVPixelBufferUnlockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: 0))
        let resultImage: UIImage = UIImage(cgImage: imageRef!)
        
        return resultImage
    }
    
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        DispatchQueue.main.async {
            
            // convert to ciimage
            let image = self.imageFromSampleBuffer(sampleBuffer: sampleBuffer)
            let ciimage: CIImage! = CIImage(image: image)
            
            let detector: CIDetector = CIDetector(ofType: CIDetectorTypeFace, context: nil, options:[CIDetectorAccuracy: CIDetectorAccuracyHigh])!
            
            // fetch parameter list
            let options = [CIDetectorSmile : true, CIDetectorEyeBlink : true]
            
            // detect face
            let faces = detector.features(in: ciimage, options: options)
            
            // remove previous face tracker
            for subview: UIView in self.view.subviews  {
                subview.removeFromSuperview()
            }
            
            for feature in faces as! [CIFaceFeature] {
                
                // check if you are smiling
                if feature.hasSmile {
                    print("smiling!!")
                }
                
                var faceRect: CGRect = (feature as AnyObject).bounds
                let widthPer = (self.view.bounds.width/image.size.width)
                let heightPer = (self.view.bounds.height/image.size.height)
                
                // UIKit has the origin at the upper left, but CoreImage has the origin at the lower left
                // so that it is aligned
                faceRect.origin.y = image.size.height - faceRect.origin.y - faceRect.size.height
                
                // magnification conversion
                faceRect.origin.x = faceRect.origin.x * widthPer
                faceRect.origin.y = faceRect.origin.y * heightPer
                faceRect.size.width = faceRect.size.width * widthPer
                faceRect.size.height = faceRect.size.height * heightPer
                
                let rect = Draw(frame: faceRect)
                self.view.addSubview(rect)
            }
        }
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}


class Draw: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.clear
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ rect: CGRect) {
        let color: UIColor = UIColor.red
        let bpath: UIBezierPath = UIBezierPath(rect: rect)
        bpath.lineWidth = 5.0
        color.set()
        bpath.stroke()
    }
}

