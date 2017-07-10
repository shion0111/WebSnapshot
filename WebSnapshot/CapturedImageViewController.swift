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
        scrollView!.backgroundColor = UIColor.black
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
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {

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
    
    // UIScrollViewDelegate
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        centerScrollViewContents(scrollView: scrollView)
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
        
        // exclude some activity types from the list (optional)
        activityViewController.excludedActivityTypes = [ UIActivityType.airDrop, UIActivityType.postToFacebook ]
        
        // present the view controller
        self.present(activityViewController, animated: true, completion: nil)
        
    }
}
