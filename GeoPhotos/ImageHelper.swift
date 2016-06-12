//
//  ImageHelper.swift
//  ExifViewer
//
//  Created by mcxiaoke on 16/5/27.
//  Copyright © 2016年 mcxiaoke. All rights reserved.
//

import Cocoa

class ImageHelper {
  
  class func thumbFromImage(url: NSURL) -> NSImage {
    let image = NSImage(contentsOfURL: url)!
    let targetHeight: CGFloat = 160.0
    let imageSize = image.size
    let smallerSize = NSSize(width: targetHeight * imageSize.width / imageSize.height, height: targetHeight)
    return NSImage(size: smallerSize, flipped: false) { (rect) -> Bool in
      image.drawInRect(rect)
      return true
    }
  }

}
