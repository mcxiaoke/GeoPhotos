//
//  ImageHelper.swift
//  ExifViewer
//
//  Created by mcxiaoke on 16/5/27.
//  Copyright © 2016年 mcxiaoke. All rights reserved.
//

import Cocoa

class ImageHelper {
  
  class func thumbFromImage(url: NSURL, height:CGFloat = 100.0) -> NSImage {
    let image = NSImage(contentsOfURL: url)!
    let targetHeight: CGFloat = height
    let imageSize = image.size
    let smallerSize = NSSize(width: targetHeight * imageSize.width / imageSize.height, height: targetHeight)
    return NSImage(size: smallerSize, flipped: false) { (rect) -> Bool in
      image.drawInRect(rect)
      return true
    }
  }

}
