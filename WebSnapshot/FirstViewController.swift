//
//  FirstViewController.swift
//  ScrollCatch
//
//  Created by admin on 3/30/17.
//  Copyright © 2017 shion. All rights reserved.
//

import UIKit
import WebKit

class FirstViewController: UIViewController, WKNavigationDelegate {

    @IBOutlet weak var baseView: UIScrollView!//UIView!
    @IBOutlet weak var urlField: UITextField!
    @IBOutlet weak var loading: UIActivityIndicatorView!
    var webview: WKWebView!
    var bSize: CGSize = CGSize.zero

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
        print(mutableYoffset)
        if mutableYoffset > contentSize.height - baseView.frame.size.height {
            scroll = false
            mutableYoffset = contentSize.height - baseView.frame.size.height
        }

        let split: CGRect = CGRect(x: 0, y: mutableYoffset, width: baseView.frame.size.width, height: contentSize.height)//baseView.frame.size.height)
        var myFrame: CGRect = webview.frame
        myFrame.origin.y = -1 * mutableYoffset
        //webview.scrollView.contentOffset = CGPoint(x:0, y:mutableYoffset-p)
        webview.frame = myFrame

        //https://stackoverflow.com/questions/24034544/dispatch-after-gcd-in-swift

        delay(1.0) {
            
            if UIApplication.shared.applicationState != UIApplicationState.active {

                UIGraphicsEndImageContext()
                self.webview.frame = CGRect(x:0, y:0, width:self.baseView.frame.size.width, height:self.baseView.frame.size.height)
                self.webview.scrollView.contentOffset =  CGPoint.zero

                //if (handler != nil){
                handler(nil, true)
                return
                //}
            }

            self.baseView.drawHierarchy(in: split, afterScreenUpdates: true)
            if scroll {

                self.innCapture(yoffset: yoffset + self.baseView.frame.size.height, contentSize: contentSize, handler: handler)

            } else {
                
                self.loading.stopAnimating()
                self.loading.isHidden = true
                
                let img = UIGraphicsGetImageFromCurrentImageContext()

                

                self.webview.frame = CGRect(x:0, y:0, width:self.baseView.frame.size.width, height:self.baseView.frame.size.height)
                self.webview.scrollView.contentOffset =  CGPoint.zero

                handler(img, false)
                
                UIGraphicsEndImageContext()
            }

        }
    }
    
    @IBAction func doCapture() {
        self.bSize = baseView.frame.size
        let contentSize = webview.scrollView.contentSize
        var frame = webview.frame
        frame.size = contentSize
        webview.frame = frame

        frame = baseView.frame
        frame.size = contentSize
        baseView.frame = frame

        UIGraphicsBeginImageContextWithOptions(contentSize, webview.scrollView.isOpaque, 0.0)
        
        loading.startAnimating()
        loading.isHidden = false
        
        
        self.innCapture(yoffset: 0, contentSize: contentSize) { (image, _) in

            var ff = self.baseView.frame
            ff.size = self.bSize
            self.baseView.frame = ff
            ff = self.webview.frame
            ff.size = self.bSize
            self.webview.frame = ff

            if image != nil {
                // Create path.
                let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
                let filePath = "\(paths[0])/\(self.getCurrentDateTickAsFilename()).jpg"
                let fileurl = URL(fileURLWithPath: filePath)
                // Save image.
                let data = UIImageJPEGRepresentation(image!, 1.0)
                do {
                    try data?.write(to: fileurl)
                } catch let error {
                    print(error)
                }
            }
        }
        
    }

    @IBAction func backward() {
        if self.webview.canGoBack {
            self.webview.goBack()
        }
    }
}
