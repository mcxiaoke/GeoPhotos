//
//  ProgressWindowController.swift
//  GeoPhotos
//
//  Created by mcxiaoke on 16/6/16.
//  Copyright © 2016年 mcxiaoke. All rights reserved.
//

import Cocoa

class ProgressWindowController: NSWindowController {
  
  var displayed:Bool = false
  
  @IBOutlet weak var view:NSView!
  @IBOutlet weak var progressBar:NSProgressIndicator!
  @IBOutlet weak var titleView:NSTextField!
  @IBOutlet weak var subtitleView:NSTextField!
  
  override var windowNibName: String?{
    return "ProgressWindowController"
  }
  
  override func awakeFromNib() {
    super.awakeFromNib()
//    setUpWindow()
  }
  
  override func windowDidLoad() {
    super.windowDidLoad()
    self.progressBar.startAnimation(nil)
  }
  
  private func setUpWindow(){
    self.window?.backgroundColor = NSColor.clearColor()
    self.window?.opaque = false
    self.view.wantsLayer = true
    self.view.layer?.masksToBounds = true
    self.view.layer?.cornerRadius = 10
    self.view.layer?.backgroundColor = NSColor.blackColor().colorWithAlphaComponent(0.4).CGColor
  }
  
  func showProgressAt(window:NSWindow, completionHandler handler: ((NSModalResponse) -> Void)?){
    if self.displayed {
      return
    }
    self.displayed = true
    window.beginSheet(self.window!) { (response) in
        self.displayed = false
      handler?(response)
    }
  }
  
  func dismissProgressAt(window:NSWindow){
    self.displayed = false
    window.endSheet(self.window!)
  }
  
  func updateProgress(title:String, subtitle:String){
    self.titleView.stringValue = title
    self.subtitleView.stringValue = subtitle
  }
    
}
