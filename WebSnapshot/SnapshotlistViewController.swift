//
//  SnapshotlistViewController.swift
//  ScrollCatch
//
//  Created by Antelis on 17/04/2017.
//  Copyright © 2017 Antelis. All rights reserved.
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
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    //  get a fileURL list sorted by modification date
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
                    .sorted(by: { $0.1 < $1.1 }) // sort ascending modification dates
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
        
        // try get thumbnail in Cache
        if let thumbRUL = getThumbnailURL(url.path) {
            cell.image.image = UIImage(contentsOfFile: thumbRUL.path)
        } else {
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
    func getThumbnailURL(_ filename: String) -> URL? {
        let paths = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)
        let name = URL(fileURLWithPath: filename).deletingPathExtension().lastPathComponent
        let path = "\(paths[0])/\(name).thumb"
        if FileManager.default.fileExists(atPath: path) {
            return URL(fileURLWithPath: path)
        }
        return nil
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
