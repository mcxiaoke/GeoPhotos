//
//  ImagePreviewController.swift
//  GeoPhotos
//
//  Created by mcxiaoke on 16/6/12.
//  Copyright © 2016年 mcxiaoke. All rights reserved.
//

import Cocoa

private let imageDisplayMaxWidth:CGFloat = 320

class ImagePreviewController: NSViewController {
  
  var url:URL?
  weak var closeView:NSImageView!
  weak var imageView:NSImageView!
  
  override func loadView() {
    self.view = NSView(frame:NSRect.zero)
    self.view.autoresizingMask = [.viewHeightSizable, .viewWidthSizable]
    self.view.autoresizesSubviews = true
    let imageView = NSImageView(frame:NSRect.zero)
    imageView.imageScaling = .scaleProportionallyUpOrDown
    imageView.imageFrameStyle = .none
    imageView.imageAlignment = .alignCenter
    self.view.addSubview(imageView)
    self.imageView = imageView
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    if let url = url {
      if let image = NSImage(contentsOf:url) {
        let size = calculateSize(image.size)
        self.imageView.frame.size = size
        self.view.frame.size = size
        self.imageView.image = image
      }
    }
  }
  
  func calculateSize(_ imageSize:NSSize) -> NSSize{
    let ow = imageSize.width
    let oh = imageSize.height
    let w = ow > imageDisplayMaxWidth ? imageDisplayMaxWidth : ow
    let h = oh * ( w / ow )
    return NSSize(width: w, height: h)
  }
    
}
