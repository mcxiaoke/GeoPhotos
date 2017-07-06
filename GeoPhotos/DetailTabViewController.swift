//
//  ImageDetailTabViewController.swift
//  ExifViewer
//
//  Created by mcxiaoke on 16/6/1.
//  Copyright © 2016年 mcxiaoke. All rights reserved.
//

import Cocoa

class DetailTabViewController: NSTabViewController {

  var imageURL:URL?
  var imageProperties:[String:[ImagePropertyItem]]? {
    didSet {
      updateUI()
    }
  }
  
  override var acceptsFirstResponder: Bool{
    return true
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    if let url = imageURL {
      loadImageProperties(url)
    }
  }
  
  func updateUI(){
    if let url = imageURL,
      let imageProperties = imageProperties {
      self.title = url.lastPathComponent ?? ""
      
      let thumbController = TabThumbViewController()
      thumbController.imageURL = url
      let tabViewItem = NSTabViewItem(viewController:thumbController)
      tabViewItem.label = "Image"
      self.addTabViewItem(tabViewItem)
      
      imageProperties.keys.sorted { $0 < $1}.forEach({ (key) in
        let controller = TabInfoViewController()
        controller.properties = imageProperties[key]
        let tabViewItem = NSTabViewItem(viewController:controller)
        tabViewItem.label = ImageCategoryPrefixKeys[key] ?? "Prop"
        self.addTabViewItem(tabViewItem)
      })
    }else {
      self.title = ""
      for i in 0..<self.childViewControllers.count {
        self.removeChildViewController(at: i)
      }
    }
  }
  
  func loadImageProperties(_ url: URL){
    DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.default).async {
      guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil) else { return }
      guard let imageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as Dictionary? else { return }
      guard let props  = imageProperties as? Dictionary<String,AnyObject> else { return }
      var properties:[String:[ImagePropertyItem]] = [:]
      properties[kCGImagePropertyCommonDictionary] = self.parseProperties(props, category: nil)
      props.forEach({ (key, value) in
        if let child  = value as? Dictionary<String,AnyObject>{
          properties[key] = self.parseProperties(child, category: key)
        }
      })
      DispatchQueue.main.async {
        self.imageProperties = properties
      }
    }
  }
  
  
  func parseProperties(_ properties: Dictionary<String,AnyObject>, category:String?)
    -> [ImagePropertyItem] {
    var items:[ImagePropertyItem] = []
    properties.forEach { (key, value) in
      if value is Dictionary<String,AnyObject> {
//        parseProperties(child, category: key)
      }else {
        let newItem = ImagePropertyItem(rawKey: key, rawValue: value, rawCat: category)
        items.append(newItem)
      }
    }
      return items.sorted { $0.key < $1.key }
  }
  
}
