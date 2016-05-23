//
//  PVImageManipulator.swift
//  podverse
//
//  Created by Mitchell Downey on 5/22/16.
//  Copyright © 2016 Mitchell Downey. All rights reserved.
//

import UIKit

class PVImageManipulator {

    static func resizeImageData(data: NSData) -> NSData? {
        guard let image = UIImage(data: data) else {
            return nil
        }
        
        var actualHeight: CGFloat = image.size.height
        var actualWidth: CGFloat = image.size.width
        let maxHeight: CGFloat = 300.0
        let maxWidth: CGFloat = 400.0
        var imgRatio: CGFloat = actualWidth / actualHeight
        let maxRatio: CGFloat = maxWidth / maxHeight
        let compressionQuality: CGFloat = 0.5
        //50 percent compression
        if actualHeight > maxHeight || actualWidth > maxWidth {
            if imgRatio < maxRatio {
                //adjust width according to maxHeight
                imgRatio = maxHeight / actualHeight
                actualWidth = imgRatio * actualWidth
                actualHeight = maxHeight
            }
            else if imgRatio > maxRatio {
                //adjust height according to maxWidth
                imgRatio = maxWidth / actualWidth
                actualHeight = imgRatio * actualHeight
                actualWidth = maxWidth
            }
            else {
                actualHeight = maxHeight
                actualWidth = maxWidth
            }
        }
        let rect: CGRect = CGRectMake(0.0, 0.0, actualWidth, actualHeight)
        UIGraphicsBeginImageContext(rect.size)
        image.drawInRect(rect)
        let img: UIImage = UIGraphicsGetImageFromCurrentImageContext()
        let imageData: NSData? = UIImageJPEGRepresentation(img, compressionQuality)
        UIGraphicsEndImageContext()
        return imageData
    }

}