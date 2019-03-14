//
//  FirstViewController.swift
//  ScrollCatch
//
//  Created by Antelis on 3/30/17.
//  Copyright © 2017 Antelis. All rights reserved.
//
//

import UIKit
import WebKit


class FirstViewController: UIViewController, WKNavigationDelegate, UITextFieldDelegate {
    
    @IBOutlet weak var baseView: UIScrollView!//UIView!
    @IBOutlet weak var urlField: UITextField!
    @IBOutlet weak var loading: LoadingIndicatorView!
    @IBOutlet weak var captureitem: UIButton?
    @IBOutlet weak var backitem: UIButton?
    
    @IBOutlet weak var urlBar: UIView? //ButtonItem: UIBarButtonItem!
    
    @IBOutlet weak var captureView: UIView!

    @IBOutlet var capturelist: UIView?    
    
    var webview: WKWebView!
    var bSize: CGSize = CGSize.zero
    var notice: NoticeBanner!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let config = WKWebViewConfiguration()
        let bounds = CGRect( x:self.view.bounds.origin.x, y:self.view.bounds.origin.y, width:baseView.bounds.width, height:baseView.bounds.height)
        
        webview = WKWebView(frame: bounds, configuration: config)
        webview?.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        webview.navigationDelegate = self
        baseView.addSubview(webview)
        
        
        rebuildToolbar(view.bounds.size)
        
        loading.isHidden = true
        
        loadURL()
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    override var prefersStatusBarHidden: Bool {
        return false
    }
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        
        print(error.localizedDescription)
    }
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        //let contentSize = webview.scrollView.contentSize
        webview.scrollView.contentOffset = CGPoint(x:0, y:0)
        self.bSize = baseView.frame.size
        self.urlField.text = webview.url?.absoluteString
    }
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        print(navigation ?? "")
    }
    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        
        print(navigationResponse)
        decisionHandler(.allow)
    }
    
    func getCurrentDateTickAsFilename() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone.ReferenceType.system
        
        let date = Date()
        let date0 = dateFormatter.string(from: date)
        let tick = date.timeIntervalSince1970.rounded()
        let timeStamp = ""
        
        return timeStamp.appendingFormat("%@-%ld", date0, Int(tick))
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        loadURL()
        return false
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
    
        super.viewWillTransition(to: size, with: coordinator)
        
        loading.setNeedsLayout()
        
        coordinator.animate(alongsideTransition: { _ in
            //  rebuild toolbar by current view size
            self.rebuildToolbar(size)
        }, completion: { _ in

        }
            
        )
        
        
    }
    
    func rebuildToolbar(_ size: CGSize) {
        
        let url = self.urlField != nil ? self.urlField.text! : "https://www.apple.com"


        //url = self.urlField.text ?? "https://www.apple.com"
        
        //let f00 = CGRect(x:0, y:0, width:size.width - 120, height:30)
        //urlField.frame = f00//UITextField(frame: f)
        urlField.delegate = self
        urlField.borderStyle = .roundedRect
        urlField.text = url
        //self.urlField.autoresizingMask = [.flexibleWidth]
        
        let btnReload = UIButton(type: .custom)
        btnReload.addTarget(self, action: #selector(self.loadURL), for:.touchUpInside)
        btnReload.frame = CGRect(x: CGFloat(urlField.frame.size.width - 30), y: CGFloat(0), width: CGFloat(30), height: CGFloat(30))
        let img = UIImage(named: "moveon")
        btnReload.setImage(img, for: .normal)//setBackgroundImage(img, for: .normal)
        urlField.rightViewMode = .always
        urlField.rightView = btnReload
        
//        let urlbaritem = UIBarButtonItem(customView: self.urlField)
//        let backitem = UIBarButtonItem(barButtonSystemItem: .rewind, target: self, action: #selector(FirstViewController.backward))
//
//        let captureitem = UIBarButtonItem(image: UIImage(named: "capture"), style:.plain, target: self, action: #selector(FirstViewController.doCapture))
        
        //self.urlBar.setItems([urlbaritem, backitem, captureitem], animated: false)
    }
    
    @IBAction func loadURL() {
        
        self.view.endEditing(true)
        if urlField.text?.isEmpty == true {
            urlField.text = "https://www.apple.com"
        }
        
        if (!(urlField.text?.hasPrefix("http://"))!) && (!(urlField.text?.hasPrefix("https://"))!) {
            let s00 = urlField.text
            urlField.text = "http://".appending(s00!)
        }
        
        guard let u00 = URL(string: urlField.text!) else { return }
        let request0 = URLRequest(url: u00)
        guard webview.load(request0) != nil else {
            print("unable to load")
            return
        }
        //webview.scrollView.isScrollEnabled = false
        
    }
    /*
     func delayForloop(_ delay: Double, closure: @escaping () -> Void) {
     DispatchQueue.main.asyncAfter(
     deadline: DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: closure)
     }
     */
    
    typealias CompletionHandler = (_: UIImage?, _: Bool) -> Void
    
    func delay(_ delay: Double, closure: @escaping() -> Void) {
        let when = DispatchTime.now() + delay
        DispatchQueue.main.asyncAfter(deadline: when, execute: closure)
        
    }
    
    func innCapture(yoffset: CGFloat, contentSize: CGSize, handler: @escaping CompletionHandler) {
        
        var scroll: Bool = true
        var mutableYoffset: CGFloat = yoffset
        
        
        // move up the super view of the webview
        if mutableYoffset >= contentSize.height + baseView.frame.origin.y {
            scroll = false
            mutableYoffset = contentSize.height + baseView.frame.origin.y
        }
        
        var myFrame: CGRect = baseView.frame
        //  only the onscreen part is captured
        let split: CGRect = CGRect(x: 0, y: -myFrame.origin.y, width: self.captureView.frame.size.width, height: self.captureView.frame.size.height)
        myFrame.origin.y -= mutableYoffset
        
        delay(0.5) {
            
            if UIApplication.shared.applicationState != UIApplication.State.active {
                
                self.webview.frame = CGRect(x:0, y:0, width:self.baseView.frame.size.width, height:self.captureView.frame.size.height)
                self.webview.scrollView.contentOffset =  CGPoint.zero
                
                //if (handler != nil){
                handler(nil, true)
                return
                //}
            }
            
            let res = self.captureView.drawHierarchy(in: split, afterScreenUpdates: true)
            
            self.baseView.frame = myFrame
            print("drawHierarchy: \(res)")
            if scroll {
                //  recursive call
                self.innCapture(yoffset: yoffset, contentSize: contentSize, handler: handler)
                
                
            } else {
                
                self.loading.stopAnimation()
                self.loading.isHidden = true
                
                let img = UIGraphicsGetImageFromCurrentImageContext()
                
                //self.webview.frame = CGRect(x:0, y:0, width:self.baseView.frame.size.width, height:self.baseView.frame.size.height)
                //self.webview.scrollView.contentOffset =  CGPoint.zero
                
                handler(img, false)
                
                UIGraphicsEndImageContext()
                
            }
            
        }
    }
    func saveThumbnailToCache(_ thumb: UIImage?, _ filename: String ) {
        let paths = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)
        let thumburl = URL(fileURLWithPath: "\(paths[0])/\(filename).thumb")
        
        let data = thumb!.jpegData(compressionQuality: 1.0)
        do {
            try data?.write(to: thumburl)
        } catch let error {
            print("Error when generating thumbnail : \(error)")
        }
        
        
    }
    
    @IBAction func doCapture() {
        captureImage()
    }
    
    @IBAction func captureImage() {
        self.bSize = baseView.frame.size
        let contentSize = webview.scrollView.contentSize
        var frame = webview.frame
        frame.size = contentSize
        webview.frame = frame
        
        frame = baseView.frame
        frame.size = contentSize
        baseView.frame = frame
        
        
        UIGraphicsBeginImageContextWithOptions(contentSize, webview.scrollView.isOpaque, UIScreen.main.scale)
        
        loading.startAnimation()
        loading.isHidden = false
        
        self.innCapture(yoffset: self.captureView.bounds.size.height, contentSize: contentSize) { (image, moveon) in
            
            //  restore the superview
            if !moveon {
                var ff0 = self.baseView.frame
                ff0.size = self.bSize
                ff0.origin.y = 0
                self.baseView.frame = ff0
                ff0 = self.webview.frame
                ff0.size = self.bSize
                self.webview.frame = ff0
            }
            
            if let image = image, let data = image.jpegData(compressionQuality: 1.0) {
                // Create path
                let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
                let filename = self.getCurrentDateTickAsFilename()
                let filepath = "\(paths[0])/\(filename).jpg"
                print("innCapture -- \(filepath)")
                let fileurl = URL(fileURLWithPath: filepath)
                
                
                
                do {
                    // Save image
                    try  data.write(to: fileurl, options:[.atomic])
                    
                    // save a thumbnail in Cache
                    let size: CGSize! = image.size
                    let cgimage = image.cgImage
                    let rect = CGRect(x: 0, y: (size.height-size.width)/2, width: size.width, height: size.width)
                    let thumbRef = cgimage?.cropping(to:rect)
                    let i00 = UIImage(cgImage:thumbRef!)
                    self.saveThumbnailToCache(i00, filename)
                    
                    
                    self.notice = NoticeBanner(message: "Snapshot saved at \(filename).jpg", dismissCallback:self.bannerDismissed)
                    
                    self.notice.show(preaction: { () -> (Void) in
                        self.setNeedsStatusBarAppearanceUpdate()
                    })
                    
                    
                } catch let error {
                    print(error)
                }
            }
             
        }
        
    }
    func bannerDismissed() {
        self.notice = nil
        self.setNeedsStatusBarAppearanceUpdate()
    }
    override var preferredStatusBarStyle: UIStatusBarStyle {
        if notice != nil {
            return .lightContent
        }
        return .default
    }
    
    @IBAction func backward() {
        if self.webview.canGoBack {
            self.webview.goBack()
            self.urlField.text = self.webview.url?.absoluteString
        }
    }
    
    
    
    @available(*, deprecated)  private func generatePDF() {//-> Data {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let filename = self.getCurrentDateTickAsFilename()
        let filepath = "\(paths[0])/\(filename).pdf"
        print("pdfCapture -- \(filepath)")
        let fileurl = URL(fileURLWithPath: filepath)
        
        
        // assign the print formatter to the print page renderer
        let renderer = UIPrintPageRenderer()
        let printFormatter = self.webview.viewPrintFormatter()
        renderer.addPrintFormatter(printFormatter, startingAtPageAt: 0)
        //let contentSize = webview.scrollView.contentSize
        // assign paperRect and printableRect values
        
        // let page = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width*UIScreen.main.scale, height: 2100)
        let page0 = CGRect(x: 0, y: 0, width: 595.2, height: 841.8)// A4, 72 dpi
        let page = CGRect(x: 8, y: 8, width: 595.2-16, height: 841.8-16)// A4, 72 dpi
        //let page0 = CGRect(x: 0, y: 0, width: contentSize.width, height: contentSize.height*0.5)
        //let page = CGRect(x: 0, y: 0, width: contentSize.width-16, height: contentSize.height*0.5)// A5
        renderer.setValue(page0, forKey: "paperRect")
        renderer.setValue(page, forKey: "printableRect")
        
        
        // create pdf context and draw each page
        //let pdfData = NSMutableData()
        //UIGraphicsBeginPDFContextToData(pdfData, .zero, nil)
        UIGraphicsBeginPDFContextToFile(fileurl.path, page0, [:])
        //let ht = 841.8-16
        for i00 in 0..<renderer.numberOfPages {
            //UIGraphicsBeginPDFPageWithInfo(CGRect(x: 8, y: 8+ht*Double(i00), width: 595.2-16, height: 841.8-16), nil)
            UIGraphicsBeginPDFPage()
            renderer.drawPage(at: i00, in: UIGraphicsGetPDFContextBounds())
            
        }
        
        UIGraphicsEndPDFContext()
        
        //        do {
        //            try pdfData.write(to: fileurl, options: .atomic)
        //        } catch let error {
        //            print(error)
        //        }
        
        //return pdfData as Data
    }
    @available(*, deprecated) @IBAction func capturePDFToImage() {
        self.generatePDF()
    }
    
}
