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
  
  var imageURL:URL?
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
  
  override func keyDown(with theEvent: NSEvent) {
    if theEvent.keyCode == 53 {
      self.dismissViewController(self)
    }else {
      super.keyDown(with: theEvent)
    }
  }
  
  func copy(_ sender:AnyObject?){
    guard let items = self.arrayController.selectedObjects as? [ImagePropertyItem] else { return }
    var textValue = ""
    items.forEach { (item) in
      textValue = "\(ImagePropertyItem.getImageIOLocalizedString(item.rawKey)) = \(item.textValue)\n"
    }
    if !textValue.isEmpty {
      let pb = NSPasteboard.general()
      pb.clearContents()
      pb.setString(textValue, forType: NSPasteboardTypeString)
    }
  }
  
  func addChangedProperty(_ item: ImagePropertyItem){
    let key = item.rawKey
    let value = item.objectValue
    print("addChangedProperty: \(key)=\(value) Type:\(type(of: value))")
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
  
  @IBAction func textValueDidChange(_ sender: NSTextField) {
    let row  = self.tableView.selectedRow
    guard let object = self.arrayController.selectedObjects.first as? ImagePropertyItem else { return }
    guard ImagePropertyItem.normalizeValue(object.rawValue) != sender.stringValue else {
      saveProperties.removeObject(forKey: object.rawKey)
      updateModifiedRowColor(row, modified: false)
      return
    }
    
    let objValue = object.objectValue
    print("textValueDidChange row=\(row) obj=\(object) objValue=\(objValue)")
    
    addChangedProperty(object)
    updateModifiedRowColor(row, modified: true)
  }
  
  @IBAction func closeMe(_ sender:AnyObject){
      self.dismissViewController(self)
  }
  
  func updateModifiedRowColor(_ row:Int, modified:Bool){
    let newColor = modified ? NSColor.red : NSColor.black
    let keyView = self.tableView.view(atColumn: 0, row: row, makeIfNecessary: false)
    if let keyTextField = keyView?.subviews[0] as? NSTextField {
      keyTextField.textColor = newColor
    }
    let valueView = self.tableView.view(atColumn: 1, row: row, makeIfNecessary: false)
    if let valueTextField = valueView?.subviews[0] as? NSTextField {
      valueTextField.textColor = newColor
    }
  }
  
  func tableViewSelectionDidChange(_ notification: Notification) {
    //    guard let object = self.arrayController.selectedObjects.first as? ImagePropertyItem else { return }
    //    let row  = self.tableView.selectedRow
    //let view = self.tableView.viewAtColumn(1, row: row, makeIfNecessary: false)
    //if let textField = view?.subviews[0] as? NSTextField {
    //textField.editable = object.editable
    //}
    //      print("tableViewSelectionDidChange row =\(row) obj=\(object)")
  }
  
  func loadImageThumb(_ url:URL){
    DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.default).async {
      let image = ImageHelper.thumbFromImage(url)
      DispatchQueue.main.async(execute: {
        self.image = image
      })
    }
  }
  
  func loadImageProperties(_ url: URL){
    DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.default).async {
      guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil) else { return }
      guard let imageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as Dictionary? else { return }
      guard let props  = imageProperties as? Dictionary<String,AnyObject> else { return }
      let properties = ImagePropertyItem.parse(props)
      DispatchQueue.main.async(execute: {
        self.properties = properties
      })
    }
  }
  
  func saveDocument(_ sender:AnyObject){
    saveDocumentAs(sender)
  }
  
  func saveDocumentAs(_ sender:AnyObject){
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
    alert.addButton(withTitle: "Save")
    alert.addButton(withTitle: "Override")
    alert.addButton(withTitle: "Cancel")
    alert.beginSheetModal(for: self.view.window!, completionHandler: { (response) in
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
  
  func writeProperties(_ url:URL, override: Bool) -> URL?{
     let directory = url.deletingLastPathComponent()
     let base = url.deletingPathExtension().lastPathComponent
     let ext = url.pathExtension
    let newName = override ? url.lastPathComponent : "\(base)_modified.\(ext)"
    let newPath = directory.appendingPathComponent(newName, isDirectory: false)
    print("writeProperties to \(newPath)")
    guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
    let imageType = CGImageSourceGetType(imageSource)!
    let data = NSMutableData()
    guard let imageDestination = CGImageDestinationCreateWithData(data, imageType, 1, nil) else { return nil }
    CGImageDestinationAddImageFromSource(imageDestination, imageSource, 0, saveProperties)
    CGImageDestinationFinalize(imageDestination)
    if let _ = try? data.write(to: newPath, options: NSData.WritingOptions.atomicWrite) {
      let alert = NSAlert()
      alert.messageText = "Image Saved"
      alert.informativeText = "Image saved to \(newPath.path)"
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

