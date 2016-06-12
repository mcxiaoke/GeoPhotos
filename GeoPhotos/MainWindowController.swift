//
//  MainWindowController.swift
//  GeoPhotos
//
//  Created by mcxiaoke on 16/6/7.
//  Copyright © 2016年 mcxiaoke. All rights reserved.
//

import Cocoa

class MainWindowController: NSWindowController {

  override var windowNibName: String?{
    return "MainWindowController"
  }
  
  override func windowDidLoad() {
    super.windowDidLoad()
    let viewController = MainViewController()
    self.contentViewController = viewController
  }
    
}
