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
    /*
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        if scrollView.zoomScale > 1 {
            if let image = imageView.image {
                let ratioW = imageView.frame.width / image.size.width
                let ratioH = imageView.frame.height / image.size.height
                let ratio = ratioW < ratioH ? ratioW:ratioH
                let newWidth = image.size.width*ratio
                let newHeight = image.size.height*ratio
                let left = 0.5 * (newWidth * scrollView.zoomScale > imageView.frame.width ? (newWidth - imageView.frame.width) : (scrollView.frame.width - scrollView.contentSize.width))
                let top = 0.5 * (newHeight * scrollView.zoomScale > imageView.frame.height ? (newHeight - imageView.frame.height) : (scrollView.frame.height - scrollView.contentSize.height))
                scrollView.contentInset = UIEdgeInsetsMake(top, left, top, left)
            }
        } else {
            scrollView.contentInset = UIEdgeInsets.zero
        }
    }
     */
    @IBAction func closeViewer() {
        dismiss(animated: true, completion: nil)
    }
/*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
