//
//  WebviewScreenshot.swift
//  ScrollCatch
//
//  Created by Antelis on 26/04/2017.
//  Copyright © 2017 Antelis. All rights reserved.
//

import Foundation
import UIKit
import WebKit

extension WKWebView {
    func screenshot() -> UIImage? {
        let totalSize = self.scrollView.contentSize
        print("\n\n **contentSize:", totalSize)
        UIGraphicsBeginImageContextWithOptions(self.bounds.size, true, 0)
        self.drawHierarchy(in: self.bounds, afterScreenUpdates: true)
        let snapshotImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return snapshotImage
    }
}
