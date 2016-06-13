//
//  ImageDetailViewController.swift
//  GeoPhotos
//
//  Created by mcxiaoke on 16/6/13.
//  Copyright © 2016年 mcxiaoke. All rights reserved.
//

import Cocoa

class ImageDetailViewController: NSViewController, NSTableViewDelegate {
  
  let saveProperties = NSMutableDictionary()
  
  var imageURL:NSURL?
  dynamic var image:NSImage?
  dynamic var properties: [ImagePropertyItem] = []
  
  @IBOutlet weak var tableView: NSTableView!
  @IBOutlet weak var arrayController: NSArrayController!
  
  override var nibName: String?{
    return "ImageDetailViewController"
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.view.appearance = NSAppearance(named: NSAppearanceNameAqua)
    if let url = imageURL {
//      loadImageThumb(url)
      loadImageProperties(url)
    }else{
//      self.image = nil
      self.properties = []
    }
  }
  
  override func keyDown(theEvent: NSEvent) {
    if theEvent.keyCode == 53 {
      self.dismissViewController(self)
    }else {
      super.keyDown(theEvent)
    }
  }
  
  func copy(sender:AnyObject?){
    guard let item = self.arrayController.selectedObjects.first as? ImagePropertyItem else { return }
    let textValue = "\(ImagePropertyItem.getImageIOLocalizedString(item.rawKey)) = \(item.textValue)"
    let pb = NSPasteboard.generalPasteboard()
    pb.clearContents()
    pb.setString(textValue, forType: NSPasteboardTypeString)
  }
  
  func addChangedProperty(item: ImagePropertyItem){
    let key = item.rawKey
    let value = item.objectValue
    print("addChangedProperty: \(key)=\(value) Type:\(value.dynamicType)")
    if ExifPropertyKeys.contains(key){
      let exifDict = saveProperties[kCGImagePropertyExifDictionary as String] as? NSMutableDictionary ?? NSMutableDictionary()
      exifDict[key] = value
      saveProperties[kCGImagePropertyExifDictionary as String] = exifDict
    }else if GPSPropertyKeys.contains(key){
      let gpsDict = saveProperties[kCGImagePropertyGPSDictionary as String] as? NSMutableDictionary ?? NSMutableDictionary()
      gpsDict[key] = value
      saveProperties[kCGImagePropertyGPSDictionary as String] = gpsDict
    }else if ImagePropertyKeys.contains(key) {
      saveProperties[key] = value
    }
  }
  
  @IBAction func textValueDidChange(sender: NSTextField) {
    let row  = self.tableView.selectedRow
    guard let object = self.arrayController.selectedObjects.first as? ImagePropertyItem else { return }
    guard ImagePropertyItem.normalizeValue(object.rawValue) != sender.stringValue else {
      saveProperties.removeObjectForKey(object.rawKey)
      updateModifiedRowColor(row, modified: false)
      return
    }
    
    let objValue = object.objectValue
    print("textValueDidChange row=\(row) obj=\(object) objValue=\(objValue)")
    
    addChangedProperty(object)
    updateModifiedRowColor(row, modified: true)
  }
  
  @IBAction func closeMe(sender:AnyObject){
      self.dismissViewController(self)
  }
  
  func updateModifiedRowColor(row:Int, modified:Bool){
    let newColor = modified ? NSColor.redColor() : NSColor.blackColor()
    let keyView = self.tableView.viewAtColumn(0, row: row, makeIfNecessary: false)
    if let keyTextField = keyView?.subviews[0] as? NSTextField {
      keyTextField.textColor = newColor
    }
    let valueView = self.tableView.viewAtColumn(1, row: row, makeIfNecessary: false)
    if let valueTextField = valueView?.subviews[0] as? NSTextField {
      valueTextField.textColor = newColor
    }
  }
  
  func tableViewSelectionDidChange(notification: NSNotification) {
    //    guard let object = self.arrayController.selectedObjects.first as? ImagePropertyItem else { return }
    //    let row  = self.tableView.selectedRow
    //let view = self.tableView.viewAtColumn(1, row: row, makeIfNecessary: false)
    //if let textField = view?.subviews[0] as? NSTextField {
    //textField.editable = object.editable
    //}
    //      print("tableViewSelectionDidChange row =\(row) obj=\(object)")
  }
  
  func loadImageThumb(url:NSURL){
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
      let image = ImageHelper.thumbFromImage(url)
      dispatch_async(dispatch_get_main_queue(), {
        self.image = image
      })
    }
  }
  
  func loadImageProperties(url: NSURL){
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
      guard let imageSource = CGImageSourceCreateWithURL(url, nil) else { return }
      guard let imageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as Dictionary? else { return }
      guard let props  = imageProperties as? Dictionary<String,AnyObject> else { return }
      let width = props[kCGImagePropertyPixelWidth as String] as! Int
      let height = props[kCGImagePropertyPixelHeight as String] as! Int
      let properties = ImagePropertyItem.parse(props).sort { $0.key < $1.key }
      dispatch_async(dispatch_get_main_queue(), {
        self.properties = properties
      })
    }
  }
  
  func saveDocument(sender:AnyObject){
    saveDocumentAs(sender)
  }
  
  func saveDocumentAs(sender:AnyObject){
    print("saveDocumentAs")
    guard let url = imageURL else { return }
    guard saveProperties.count > 0 else { return }
    let alert = NSAlert()
    alert.messageText = "Image Properties"
    var infoText = "Save these chagned properties?\n"
    saveProperties.forEach({ (key, value) in
      infoText += "\(key)=\(value)\n"
    })
    alert.informativeText = infoText
    alert.addButtonWithTitle("Save")
    alert.addButtonWithTitle("Override")
    alert.addButtonWithTitle("Cancel")
    alert.beginSheetModalForWindow(self.view.window!, completionHandler: { (response) in
      switch response {
      case NSAlertFirstButtonReturn:
        self.writeProperties(url, override: false)
        self.saveProperties.removeAllObjects()
      case NSAlertSecondButtonReturn:
        self.writeProperties(url, override: true)
        self.saveProperties.removeAllObjects()
        self.imageURL = url
      case NSAlertThirdButtonReturn: break
      default: break
      }
    })
    
  }
  
  func writeProperties(url:NSURL, override: Bool) -> NSURL?{
    guard let directory = url.URLByDeletingLastPathComponent else { return nil }
    guard let base = url.URLByDeletingPathExtension?.lastPathComponent else { return nil }
    guard let ext = url.pathExtension else { return nil }
    let newName = override ? url.lastPathComponent! : "\(base)_modified.\(ext)"
    let newPath = directory.URLByAppendingPathComponent(newName, isDirectory: false)
    print("writeProperties to \(newPath)")
    guard let imageSource = CGImageSourceCreateWithURL(url, nil) else { return nil }
    let imageType = CGImageSourceGetType(imageSource)!
    let data = NSMutableData()
    guard let imageDestination = CGImageDestinationCreateWithData(data, imageType, 1, nil) else { return nil }
    CGImageDestinationAddImageFromSource(imageDestination, imageSource, 0, saveProperties)
    CGImageDestinationFinalize(imageDestination)
    if let _ = try? data.writeToURL(newPath, options: NSDataWritingOptions.AtomicWrite) {
      let alert = NSAlert()
      alert.messageText = "Image Saved"
      alert.informativeText = "Image saved to \(newPath.path!)"
      alert.runModal()
      return newPath
    }
    return nil
  }
  
  // https://github.com/oopww1992/WWimageExif
  // http://oleb.net/blog/2011/09/accessing-image-properties-without-loading-the-image-into-memory/
  // https://developer.apple.com/library/ios/documentation/GraphicsImaging/Reference/CGImageProperties_Reference/index.html
  // http://sandeepc.livejournal.com/656.html
  // http://stackoverflow.com/questions/4169677/
  // CFDictionary can cast to Dictionary?
  // CFString can cast to String
  // http://stackoverflow.com/questions/32716146/cfdictionary-wont-bridge-to-nsdictionary-swift-2-0-ios9
  
  
}

