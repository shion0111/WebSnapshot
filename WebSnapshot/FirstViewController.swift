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


class FirstViewController: UIViewController, WKNavigationDelegate {
    
    @IBOutlet weak var baseView: UIScrollView!//UIView!
    @IBOutlet weak var urlField: UITextField!
    @IBOutlet weak var loading: LoadingIndicatorView!
    @IBOutlet weak var urlBarButtonItem: UIBarButtonItem!
    
    @IBOutlet weak var captureView: UIView!

    
    var webview: WKWebView!
    var bSize: CGSize = CGSize.zero
    var notice: NoticeBanner!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.urlField.autoresizingMask = [.flexibleWidth]
        
        let config = WKWebViewConfiguration()
        let bounds = CGRect( x:self.view.bounds.origin.x, y:self.view.bounds.origin.y, width:baseView.bounds.width, height:baseView.bounds.height)
        
        webview = WKWebView(frame: bounds, configuration: config)
        webview?.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        webview.navigationDelegate = self
        baseView.addSubview(webview)
        
        let btnReload = UIButton(type: .custom)
        btnReload.addTarget(self, action: #selector(self.loadURL), for:.touchUpInside)
        btnReload.frame = CGRect(x: CGFloat(urlField.frame.size.width - 30), y: CGFloat(0), width: CGFloat(30), height: CGFloat(30))
        let img = UIImage(named: "moveon")
        btnReload.setImage(img, for: .normal)//setBackgroundImage(img, for: .normal)
        urlField.rightViewMode = .always
        urlField.rightView = btnReload
        
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
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        //let contentSize = webview.scrollView.contentSize
        webview.scrollView.contentOffset = CGPoint(x:0, y:0)
        self.bSize = baseView.frame.size
        self.urlField.text = webview.url?.absoluteString
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
            
            self.urlField.frame = CGRect(x:0, y:0, width:size.width - 95, height:self.urlField.frame.size.height)
        }, completion: { _ in
            
        }
            
        )
        
        
        
    }
    
    @IBAction func loadURL() {
        
        self.view.endEditing(true)
        if urlField.text?.isEmpty == true {
            urlField.text = "http://www.apple.com"
        }
        
        if (!(urlField.text?.hasPrefix("http://"))!) && (!(urlField.text?.hasPrefix("https://"))!) {
            let s = urlField.text
            urlField.text = "http://".appending(s!)
        }
        
        guard let u = URL(string: urlField.text!) else { return }
        let request0 = URLRequest(url: u)
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
            
            if UIApplication.shared.applicationState != UIApplicationState.active {
                
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
        
        let data = UIImageJPEGRepresentation(thumb!, 1.0)
        do {
            try data?.write(to: thumburl)
        } catch let error {
            print("Error when generating thumbnail : \(error)")
        }
        
        
    }
    /*
     extension UIView {
     func capture() -> UIImage? {
     var image: UIImage?
     
     if #available(iOS 10.0, *) {
     let format = UIGraphicsImageRendererFormat()
     format.opaque = isOpaque
     let renderer = UIGraphicsImageRenderer(size: frame.size, format: format)
     image = renderer.image { context in
     drawHierarchy(in: frame, afterScreenUpdates: true)
     }
     } else {
     UIGraphicsBeginImageContextWithOptions(frame.size, isOpaque, UIScreen.main.scale)
     drawHierarchy(in: frame, afterScreenUpdates: true)
     image = UIGraphicsGetImageFromCurrentImageContext()
     UIGraphicsEndImageContext()
     }
     
     return image
     }
     }
     */
    @IBAction func doCapture() {
        
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
                var ff = self.baseView.frame
                ff.size = self.bSize
                ff.origin.y = 0
                self.baseView.frame = ff
                ff = self.webview.frame
                ff.size = self.bSize
                self.webview.frame = ff
            }
            
            if image != nil {
                // Create path
                let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
                let filename = self.getCurrentDateTickAsFilename()
                let filepath = "\(paths[0])/\(filename).jpg"
                print("innCapture -- \(filepath)")
                let fileurl = URL(fileURLWithPath: filepath)
                
                
                let data = UIImageJPEGRepresentation(image!, 1.0)
                do {
                    // Save image
                    try data?.write(to: fileurl)
                    
                    // save a thumbnail in Cache
                    let size: CGSize! = image?.size
                    let cgimage = image?.cgImage
                    let rect = CGRect(x: 0, y: (size.height-size.width)/2, width: size.width, height: size.width)
                    let thumbRef = cgimage?.cropping(to:rect)
                    let i0 = UIImage(cgImage:thumbRef!)
                    self.saveThumbnailToCache(i0, filename)
                    
                    
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
}
