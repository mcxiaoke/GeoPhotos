//
//  TabThumbViewController.swift
//  ExifViewer
//
//  Created by mcxiaoke on 16/6/2.
//  Copyright © 2016年 mcxiaoke. All rights reserved.
//

import Cocoa

class TabThumbViewController: NSViewController {
  
  var imageURL:NSURL?
  @IBOutlet weak var imageView: NSImageView!
  
  override var nibName: String?{
    return "TabThumbViewController"
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    if let url = imageURL {
      self.imageView?.image = NSImage(contentsOfURL:url)
    }
  }
  
  func loadImageThumb(url:NSURL){
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
      let image = ImageHelper.thumbFromImage(url)
      dispatch_async(dispatch_get_main_queue(), {
        self.imageView?.image = image
      })
    }
  }
  
    
}
