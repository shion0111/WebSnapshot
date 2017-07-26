//
//  CapturedImageViewContorller.swift
//  ScrollCatch
//
//  Created by Antelis on 26/05/2017.
//  Copyright © 2017 shion. All rights reserved.
//

import UIKit

class CapturedImageViewController: UIViewController, UIScrollViewDelegate {

    var imageView: UIImageView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var closeBtn: UIBarButtonItem!
    var doubleTapGestureRecognizer: UITapGestureRecognizer!
    var fileURL: URL!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.navigationItem.leftBarButtonItem = self.closeBtn
        setupGestureRecognizer()
    }

    override var prefersStatusBarHidden: Bool {
        return navigationController?.isNavigationBarHidden == true
    }

    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return UIStatusBarAnimation.slide
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        do {
            self.title = NSString(string: self.fileURL.absoluteString).lastPathComponent
            let imagedata = try Data(contentsOf: self.fileURL)
            imageView = UIImageView(image:UIImage(data: imagedata))


            imageView.frame = CGRect(x: 0, y: 0, width: (imageView.image?.size.width)!, height: (imageView.image?.size.height)!)
            imageView.contentMode = .center
            scrollView!.addSubview(imageView)
            imageView.isUserInteractionEnabled = false
            
            
        } catch {
            print("Error loading image : \(error)")
        }
    }
    override func viewWillLayoutSubviews() {
        scrollView!.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        //scrollView!.backgroundColor = UIColor.black
        var minZoom = min(self.view.bounds.size.width / (imageView.image?.size.width)!, self.view.bounds.size.height / (imageView.image?.size.height)!)

        if minZoom > 1.0 {
            minZoom = 1.0
        }

        scrollView!.contentSize = (imageView.image?.size)!
        scrollView!.minimumZoomScale = minZoom
        scrollView!.setZoomScale(scrollView.minimumZoomScale, animated: false)
        
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        centerScrollViewContents(scrollView: scrollView)
    }
    func handleHideBarTap(recognizer: UITapGestureRecognizer) {
        if (self.navigationController?.isNavigationBarHidden)! {
            self.navigationController?.setNavigationBarHidden(false, animated: true)
        } else {
            self.navigationController?.setNavigationBarHidden(true, animated: true)
        }
    }
    func handleDoubleTap(recognizer: UITapGestureRecognizer) {
        if scrollView.zoomScale > scrollView.minimumZoomScale {
            scrollView.setZoomScale(scrollView.minimumZoomScale, animated: true)
        } else {
            scrollView.setZoomScale(scrollView.maximumZoomScale, animated: true)
        }
    }
    func setupGestureRecognizer() {

        scrollView.delegate = self

        let singleTap = UITapGestureRecognizer(target: self, action: #selector(CapturedImageViewController.handleHideBarTap(recognizer:)))
        singleTap.numberOfTapsRequired = 1
        scrollView.addGestureRecognizer(singleTap)
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(CapturedImageViewController.handleDoubleTap(recognizer:)))
        doubleTap.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(doubleTap)
        
        singleTap.require(toFail: doubleTap)
    }
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.imageView
    }
    
    func centerScrollViewContents(scrollView: UIScrollView) {
        let contentSize = scrollView.contentSize
        let scrollViewSize = scrollView.frame.size
        var contentOffset = scrollView.contentOffset
        
        if contentSize.width < scrollViewSize.width {
            contentOffset.x = -(scrollViewSize.width - contentSize.width) / 2.0
        }
        
        if contentSize.height < scrollViewSize.height {
            contentOffset.y = -(scrollViewSize.height - contentSize.height) / 2.0
        }
        
        scrollView.setContentOffset(contentOffset, animated: false)
    }
    
    //  Delete thumbnail in Caches
    func deleteThumbnail(_ fileurl: URL?) {
        
        let paths = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)
        let filename: String = (fileurl?.deletingPathExtension().lastPathComponent)!
        let thumburl = URL(fileURLWithPath: "\(paths[0])/\(filename).thumb")
        if FileManager.default.fileExists(atPath: thumburl.path) {
            do {
                try FileManager.default.removeItem(at: thumburl)
            } catch let error {
                print(error)
            }
        }
    }
    
    // UIScrollViewDelegate
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        let imgViewSize: CGSize! = self.imageView.frame.size
        let imageSize: CGSize! = self.imageView.image?.size
        var realImgSize: CGSize
        if imageSize.width / imageSize.height > imgViewSize.width / imgViewSize.height {
            realImgSize = CGSize(width: imgViewSize.width, height: imgViewSize.width / imageSize.width * imageSize.height)
        } else {
            realImgSize = CGSize(width: imgViewSize.height / imageSize.height * imageSize.width, height: imgViewSize.height)
        }
        var fr: CGRect = CGRect.zero
        fr.size = realImgSize
        self.imageView.frame = fr
        
        let scrSize: CGSize = scrollView.frame.size
        let offx: CGFloat = (scrSize.width > realImgSize.width ? (scrSize.width - realImgSize.width) / 2 : 0)
        let offy: CGFloat = (scrSize.height > realImgSize.height ? (scrSize.height - realImgSize.height) / 2 : 0)
        scrollView.contentInset =  UIEdgeInsets(top:offy, left: offx, bottom: offy, right: offx)
        
        // The scroll view has zoomed, so you need to re-center the contents
        let scrollViewSize: CGSize = self.scrollViewVisibleSize()
        
        // First assume that image center coincides with the contents box center.
        // This is correct when the image is bigger than scrollView due to zoom
        var imageCenter: CGPoint = CGPoint(x: self.scrollView.contentSize.width/2.0, y:
            self.scrollView.contentSize.height/2.0)
        
        let scrollViewCenter: CGPoint = self.scrollViewCenter()
        
        //if image is smaller than the scrollView visible size - fix the image center accordingly
        if self.scrollView.contentSize.width < scrollViewSize.width {
            imageCenter.x = scrollViewCenter.x
        }
        
        if self.scrollView.contentSize.height < scrollViewSize.height {
            imageCenter.y = scrollViewCenter.y
        }
        
        self.imageView.center = imageCenter
        
    }
    //return the scroll view center
    func scrollViewCenter() -> CGPoint {
        let scrollViewSize: CGSize = self.scrollViewVisibleSize()
        return CGPoint(x: scrollViewSize.width/2.0, y: scrollViewSize.height/2.0)
    }
    // Return scrollview size without the area overlapping with tab and nav bar.
    func scrollViewVisibleSize() -> CGSize {
        
        let contentInset: UIEdgeInsets = self.scrollView.contentInset
        let scrollViewSize: CGSize = self.scrollView.bounds.standardized.size
        let width: CGFloat = scrollViewSize.width - contentInset.left - contentInset.right
        let height: CGFloat = scrollViewSize.height - contentInset.top - contentInset.bottom
        return CGSize(width:width, height:height)
    }
    
    
    @IBAction func closeViewer() {
        dismiss(animated: true, completion: nil)
        
    }
    
    @IBAction func promptDelete() {
        let alert = UIAlertController(title: "Confirm to delete this file?", message: "", preferredStyle: UIAlertControllerStyle.alert)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel) { (_ : UIAlertAction) -> Void in
            
        }
        let deleteAction = UIAlertAction(title: "Delete", style: UIAlertActionStyle.destructive) { (_ : UIAlertAction) -> Void in
            let manager = FileManager.default
            do {
                try manager.removeItem(at: self.fileURL)
                self.deleteThumbnail(self.fileURL)
                self.closeViewer()
            } catch {
                print("Could not delete this file: \(error)")
            }
        }
        
        alert.addAction(cancelAction)
        alert.addAction(deleteAction)
        self.present(alert, animated: true, completion: nil)
        
    }
    @IBAction func activityViewAction() {
        
        // set up activity view controller
        let activityViewController = UIActivityViewController(activityItems: ["Saved snapshot", self.fileURL], applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = self.view // so that iPads won't crash
        
        activityViewController.excludedActivityTypes = [ UIActivityType.postToFacebook ]
        
        // present the view controller
        self.present(activityViewController, animated: true, completion: nil)
        
    }
}
