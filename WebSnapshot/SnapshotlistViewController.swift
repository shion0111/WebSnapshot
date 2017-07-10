//
//  SnapshotlistViewController.swift
//  ScrollCatch
//
//  Created by Antelis on 17/04/2017.
//  Copyright © 2017 shion. All rights reserved.
//

import UIKit
import ImageIO

private let reuseIdentifier = "sCell"

class SnapshotlistViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {

    @IBOutlet weak var snapshotListView: UICollectionView!
    var capturedIMGs: [URL] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        /*Don't call this when using in-storyboard collectionview cell */
        //self.collectionView!.register(SnapshotImageViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewWillAppear(_ animated: Bool) {

        super.viewWillAppear(animated)
        
        let layout = self.snapshotListView.collectionViewLayout as! UICollectionViewFlowLayout
        layout.headerReferenceSize = CGSize(width: 300, height: 20)
        layout.sectionHeadersPinToVisibleBounds = true
        capturedIMGs = listFilesAt(path: "")
        snapshotListView.reloadData()
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

    // MARK: UICollectionViewDataSource

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    //  get a sorted fileURL list
    func listFilesAt(path: String) -> [URL] {
        let fileManager = FileManager.default

        let _: URL = URL(fileURLWithPath: path)
        var urls = [URL]()

        do {
            let resourceKeys: [URLResourceKey] = [.isDirectoryKey]//[.creationDateKey, .isDirectoryKey]
            let documentsURL = try fileManager.url(for: .documentDirectory,
                                                   in: .userDomainMask, appropriateFor: nil, create: false)
            if let urlArray = try? fileManager.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: [.contentModificationDateKey],
                                                                           options:.skipsHiddenFiles) {
                let m = urlArray.map { url in
                    (url.path, (try? url.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? Date.distantPast)
                    }
                    .sorted(by: { $0.1 < $1.1 }) // sort descending modification dates
                    .map { $0.0 } // extract file names
                
                for case let path in m {
                    let fileURL = URL(fileURLWithPath: path)
                    let resourceValues = try fileURL.resourceValues(forKeys: Set(resourceKeys))
                    if !(resourceValues.isDirectory!) && (fileURL.pathExtension.lowercased() == "jpg") {
                        
                        urls.append(fileURL)
                    }
                }
                
            } else {
              return urls
            }
            
        } catch {
                print(error)
        }
 
        return urls
    }
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {

        return capturedIMGs.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! SnapshotImageViewCell
        cell.layer.borderWidth = 0.25
        cell.layer.borderColor = UIColor.lightGray.cgColor
        
        let fileName = NSString(string: capturedIMGs[indexPath.row].absoluteString).lastPathComponent
        cell.caption.text = fileName
        
        let url = capturedIMGs[indexPath.row]
        
        // Generating reasonably sized thumbnails by CGImageSource
        let src = CGImageSourceCreateWithURL(url as CFURL, nil)
        let d = [
            
            kCGImageSourceCreateThumbnailWithTransform: true as AnyObject,
            kCGImageSourceCreateThumbnailFromImageIfAbsent: true as AnyObject,
            kCGImageSourceThumbnailMaxPixelSize: Int(1024)
            ] as [CFString : Any]
        let imref = CGImageSourceCreateThumbnailAtIndex(src!, 0, d as CFDictionary)
        if imref != nil {
            cell.image.image = UIImage(cgImage: imref!, scale: 1, orientation: UIImageOrientation.up)
        }
        
        return cell
    }
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        let header: UICollectionReusableView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "HeaderTitle", for: indexPath)
        
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            let name = Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String
            let title = header.viewWithTag(222) as? UILabel!
            title?.text = "| \u{00A9} 2017 Antelis Wu | "+name!+" "+version+" |"
        }
        
        return header
    }
    override var prefersStatusBarHidden: Bool {
        return false
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    //override func prepareForSegue(segue: UIStoryboardSegue!, sender: AnyObject!) {
        print(segue.identifier ?? "no value")
        if segue.identifier == "viewSnapshot" {
            let indexPath = snapshotListView.indexPath(for: sender as! UICollectionViewCell)
            let fileUrl = capturedIMGs[(indexPath?.row)!]

            let navController = segue.destination as? UINavigationController
            if let viewer = navController?.topViewController as? CapturedImageViewController {
                viewer.fileURL = fileUrl
            }
            print(sender ?? "nothing!!")
        }
    }
    
}
