//
//  QRCodeScannerViewController.swift
//  WebSnapshot
//
//  Created by Antelis on 2018/2/19.
//  Copyright © 2018 shion. All rights reserved.
//

import UIKit
import AVFoundation
import Vision

protocol QRCodeDelegate: AnyObject {
    func getQRCodeURLString(_ string: String, _ scanview: QRCodeScanner)
    func cleanupFinished(_ scanview: QRCodeScanner)
    
}

class QRCodeScanner: UIView, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    private var videolayer: AVCaptureVideoPreviewLayer?
    private var session: AVCaptureSession?
    weak var receiver: QRCodeDelegate?
    private var output: AVCaptureVideoDataOutput?
    private var input: AVCaptureInput?
    
    convenience init(frame: CGRect, receiver: QRCodeDelegate) {
        self.init(frame: frame)
        self.receiver = receiver
        
    }
    
    func prepareScanningSession() -> Bool {
        
        var result: Bool = false
        session = AVCaptureSession()
        
        self.session?.beginConfiguration()
        
        if let session = self.session {
            if session.canSetSessionPreset(AVCaptureSession.Preset.high) {
                if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: AVMediaType.video, position: .back) {
                    do {
                        self.input = try AVCaptureDeviceInput(device: device)
                        if let input = self.input, session.canAddInput(input) {
                            session.addInput(input)
                            self.output = AVCaptureVideoDataOutput()
                            self.output?.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
                            self.output?.alwaysDiscardsLateVideoFrames = true
                            if let out = self.output, session.canAddOutput(out) {
                                session.addOutput(out)
                                session.sessionPreset = AVCaptureSession.Preset.high
                                out.setSampleBufferDelegate(self, queue: DispatchQueue(label: "com.qrcode.scanQueue"))
                                
                                result = true
                            }
                        }
                    } catch (let error) {
                        print(error.localizedDescription)
                    }
                    
                }
            }
            
        }
        self.session?.commitConfiguration()
        
        return result
    }
    
    func getScannerReady() {
        if let session = self.session {
            self.videolayer = AVCaptureVideoPreviewLayer(session: session)
            self.videolayer?.frame = CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height)
            self.videolayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
            self.layer.addSublayer(self.videolayer!)
            
            let shape = CAShapeLayer()
            let width = self.frame.width - 20
            shape.frame = CGRect(x: 10, y: 10, width: width, height: width)
            shape.lineWidth = 2
            shape.fillColor = UIColor.clear.cgColor
            shape.strokeColor = UIColor.green.cgColor
            let path = UIBezierPath(rect: CGRect(x:0, y:0, width:width, height:width))
            shape.path = path.cgPath
            self.videolayer?.addSublayer(shape)
            
            self.session?.startRunning()
        }
        
    }
    func finishScanning() {
        cleanupScanningSession()
        if let receiver = self.receiver {
            receiver.cleanupFinished(self)
        }
    }
    private func cleanupScanningSession() {
        if let session = self.session, let out = self.output {
            session.stopRunning()
            out.setSampleBufferDelegate(nil, queue: nil)
            if let input = self.input {
                session.removeInput(input)
                session.removeOutput(out)
                self.input = nil
                self.output = nil
                self.session = nil
            }
        }
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        if let imgBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
            CVPixelBufferLockBaseAddress(imgBuffer, .readOnly)
            let width = CVPixelBufferGetWidthOfPlane(imgBuffer, 0)
            let height = CVPixelBufferGetHeightOfPlane(imgBuffer, 0)
            let bytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(imgBuffer, 0)
            if let vidbuf: UnsafeMutableRawPointer = CVPixelBufferGetBaseAddressOfPlane(imgBuffer, 0) {
                CVPixelBufferUnlockBaseAddress(imgBuffer, .readOnly)
                let space: CGColorSpace = CGColorSpaceCreateDeviceRGB()
                if let context = CGContext(data: vidbuf, width: width, height: height, bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: space, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue) {
                    
                    if let imgRef: CGImage = context.makeImage() {
                        if #available(iOS 11.0, *) {
                            let handler = VNImageRequestHandler(cgImage: imgRef, options: [:])
                            let detectRequest = VNDetectBarcodesRequest(completionHandler: { (request, error) in
                                if let err = error {
                                    print(err.localizedDescription)
                                } else if let results = request.results {
                                    for obs in results {
                                        if let obss = obs as? VNBarcodeObservation {
                                            print(obss.payloadStringValue ?? "")
                                            if let payloadString = obss.payloadStringValue,
                                                let receiver = self.receiver {
                                                receiver.getQRCodeURLString(payloadString, self)
                                            }
                                            break
                                        }
                                        
                                    }
                                }
                            })
                            
                            
                            do {
                                try handler.perform([detectRequest])
                                
                            } catch (let error) {
                                print(error.localizedDescription)
                            }
                            
                        } else {
                            // Fallback on earlier versions
                        }
                        
                       
                        
                        
                    }
                }
                
            }
            
        }
        
    }
    deinit {
        cleanupScanningSession()
    }
    
}

import UIKit
import AVFoundation

class QRCodeScannerViewController: UIViewController, QRCodeDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        addQRCodeDetectAction()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
    }
    func addQRCodeDetectAction() {
        
        let btn = UIButton(type: .system)
        btn.frame = CGRect(x: 20, y: 64, width: 180, height: 40)
        btn.setTitle("test QRCode scan", for: .normal)
        btn.addTarget(self, action: #selector(qrCodeAction), for: .touchUpInside)
        self.view.addSubview(btn)
    }
    @objc func qrCodeAction(_ sneder:Any?) {
        //return
        switch (AVCaptureDevice.authorizationStatus(for: AVMediaType.video)) {
        case .authorized:
            loadQRCodeDetection()
            break
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: AVMediaType.video, completionHandler: { (granted) in
                if granted {
                    
                    DispatchQueue.main.async {
                        self.loadQRCodeDetection()
                    }
                }
            })
            break
        case .denied, .restricted:
            break
        @unknown default:
            break
        }
    }
    func loadQRCodeDetection() {
        let qrcodeview = QRCodeScanner(frame: CGRect(x: 20, y: 120, width:256, height:256), receiver: self)
        self.view.addSubview(qrcodeview)
        if qrcodeview.prepareScanningSession() {
            qrcodeview.getScannerReady()
        }
    }
    // MARK: -
    func getQRCodeURLString(_ string: String, _ scanview: QRCodeScanner) {
        print("String found: \(string)")
        scanview.finishScanning()
    }
    func cleanupFinished(_ scanview: QRCodeScanner) {
        DispatchQueue.main.async {
            scanview.removeFromSuperview()
        }
    }
    
}
