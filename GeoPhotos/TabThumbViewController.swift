//
//  TabThumbViewController.swift
//  ExifViewer
//
//  Created by mcxiaoke on 16/6/2.
//  Copyright © 2016年 mcxiaoke. All rights reserved.
//

import Cocoa

class TabThumbViewController: NSViewController {
  
  var imageURL:URL?
  @IBOutlet weak var imageView: NSImageView!
  
  override var nibName: String?{
    return "TabThumbViewController"
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    if let url = imageURL {
      self.imageView?.image = NSImage(contentsOf:url)
    }
  }
  
  func loadImageThumb(_ url:URL){
    DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.default).async {
      let image = ImageHelper.thumbFromImage(url)
      DispatchQueue.main.async(execute: {
        self.imageView?.image = image
      })
    }
  }
  
    
}
